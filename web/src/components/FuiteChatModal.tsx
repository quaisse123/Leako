import { useEffect, useRef, useState } from 'react'
import {
  Loader2,
  MessageCircle,
  Mic,
  Pause,
  Play,
  Send,
  X,
} from 'lucide-react'
import { getMessagesByFuite, createTextMessage, createAudioMessage } from '../api/messageApi'
import { getUser } from '../api/jwtService'
import { fileUrl } from '../utils/fileUrl'
import type { FuiteMessageResponseDto } from '../types'

interface FuiteChatModalProps {
  fuiteId: number
  numeroTag: string
  onClose: () => void
}

/** Formate une durée en secondes → "mm:ss". */
function formatDuration(seconds: number): string {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0')
  const s = Math.floor(seconds % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

/** Formate une date ISO → "HH:mm". */
function formatTime(dateStr?: string): string {
  if (!dateStr) return ''
  try {
    const dt = new Date(dateStr)
    return `${dt.getHours().toString().padStart(2, '0')}:${dt.getMinutes().toString().padStart(2, '0')}`
  } catch {
    return ''
  }
}

/** Barres de son statiques (vague audio). */
function AudioWave({ color, progress }: { color: string; progress: number }) {
  const bars = Array.from({ length: 20 }, (_, i) => 4 + (i % 5) * 3)
  const progressIndex = progress * bars.length
  return (
    <div className="flex items-center gap-[3px] h-6">
      {bars.map((h, i) => (
        <div
          key={i}
          className="w-[2.5px] rounded-full"
          style={{
            height: `${h}px`,
            backgroundColor: i <= progressIndex ? color : `${color}66`,
          }}
        />
      ))}
    </div>
  )
}

/**
 * Modal de conversation autour d'une fuite.
 * Réplique fuite_chat_page.dart (mobile) : messages texte + audio (enregistrement MediaRecorder).
 * Design OCP : bulles vertes (moi) / blanches (autres), avatars verts.
 */
export default function FuiteChatModal({ fuiteId, numeroTag, onClose }: FuiteChatModalProps) {
  const user = getUser()
  const myId = user?.id ?? 1

  const [messages, setMessages] = useState<FuiteMessageResponseDto[]>([])
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const [text, setText] = useState('')

  // ─── Enregistrement audio ─────────────────────────────
  const [recording, setRecording] = useState(false)
  const [recordSeconds, setRecordSeconds] = useState(0)
  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const chunksRef = useRef<Blob[]>([])
  const timerRef = useRef<number | null>(null)

  // ─── Lecture audio ────────────────────────────────────
  const audioRef = useRef<HTMLAudioElement | null>(null)
  const [playingId, setPlayingId] = useState<number | null>(null)
  const [playProgress, setPlayProgress] = useState(0)
  const [audioLoadingId, setAudioLoadingId] = useState<number | null>(null)

  const listRef = useRef<HTMLDivElement | null>(null)

  const loadMessages = async () => {
    try {
      const msgs = await getMessagesByFuite(fuiteId)
      setMessages(msgs)
    } catch {
      /* silencieux */
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void loadMessages()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fuiteId])

  // Scroll vers le bas à chaque nouveau message
  useEffect(() => {
    listRef.current?.scrollTo({ top: listRef.current.scrollHeight, behavior: 'smooth' })
  }, [messages, loading])

  // Nettoyage à la fermeture
  useEffect(() => {
    return () => {
      if (timerRef.current) window.clearInterval(timerRef.current)
      audioRef.current?.pause()
    }
  }, [])

  // ─── Envoi texte ──────────────────────────────────────
  const sendText = async () => {
    const content = text.trim()
    if (!content || sending) return
    setSending(true)
    setText('')
    try {
      await createTextMessage({
        fuiteId,
        utilisateurId: myId,
        contenuTexte: content,
      })
      await loadMessages()
    } catch {
      /* silencieux */
    } finally {
      setSending(false)
    }
  }

  // ─── Enregistrement audio ─────────────────────────────
  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const recorder = new MediaRecorder(stream)
      chunksRef.current = []
      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data)
      }
      recorder.onstop = () => {
        stream.getTracks().forEach((t) => t.stop())
      }
      recorder.start()
      mediaRecorderRef.current = recorder
      setRecording(true)
      setRecordSeconds(0)
      timerRef.current = window.setInterval(() => {
        setRecordSeconds((s) => s + 1)
      }, 1000)
    } catch {
      alert("L'enregistrement audio n'est pas disponible ou le micro est bloqué.")
    }
  }

  const stopRecording = async () => {
    const recorder = mediaRecorderRef.current
    if (!recorder || recorder.state === 'inactive') {
      cancelRecording()
      return
    }
    if (timerRef.current) window.clearInterval(timerRef.current)
    setRecording(false)

    const duration = recordSeconds
    recorder.stop()
    mediaRecorderRef.current = null

    await new Promise<void>((resolve) => {
      recorder.onstop = () => {
        const stream = (recorder.stream as MediaStream | undefined)
        stream?.getTracks().forEach((t) => t.stop())
        resolve()
      }
    })

    if (chunksRef.current.length === 0) return
    const blob = new Blob(chunksRef.current, { type: 'audio/webm' })
    if (blob.size === 0) return
    const file = new File([blob], `audio_${Date.now()}.webm`, { type: 'audio/webm' })

    setSending(true)
    try {
      await createAudioMessage({
        fuiteId,
        utilisateurId: myId,
        audioFile: file,
        dureeAudioSecondes: duration,
      })
      await loadMessages()
    } catch {
      /* silencieux */
    } finally {
      setSending(false)
    }
  }

  const cancelRecording = () => {
    if (timerRef.current) window.clearInterval(timerRef.current)
    const recorder = mediaRecorderRef.current
    if (recorder && recorder.state !== 'inactive') {
      recorder.onstop = null
      recorder.stop()
      recorder.stream.getTracks().forEach((t) => t.stop())
    }
    mediaRecorderRef.current = null
    chunksRef.current = []
    setRecording(false)
    setRecordSeconds(0)
  }

  // ─── Lecture audio ────────────────────────────────────
  const togglePlayPause = (msg: FuiteMessageResponseDto) => {
    if (!msg.cheminAudio) return
    const url = fileUrl(msg.cheminAudio)
    const audio = audioRef.current ?? new Audio()
    audioRef.current = audio

    if (playingId === msg.id) {
      if (!audio.paused) {
        audio.pause()
      } else {
        void audio.play()
      }
      return
    }

    audio.pause()
    setAudioLoadingId(msg.id)
    setPlayProgress(0)

    audio.src = url
    audio.ontimeupdate = () => {
      if (audio.duration && !Number.isNaN(audio.duration)) {
        setPlayProgress(audio.currentTime / audio.duration)
      }
    }
    audio.onended = () => {
      setPlayingId(null)
      setPlayProgress(0)
      setAudioLoadingId(null)
    }
    audio.onerror = () => {
      setPlayingId(null)
      setPlayProgress(0)
      setAudioLoadingId(null)
    }
    audio.play().then(() => {
      setPlayingId(msg.id)
      setAudioLoadingId(null)
    }).catch(() => {
      setAudioLoadingId(null)
      setPlayingId(null)
    })
  }

  // ─── Rendu ────────────────────────────────────────────
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40" onClick={onClose}>
      <div
        className="w-full max-w-2xl h-[75vh] bg-[#F8F9FA] rounded-t-3xl flex flex-col shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Poignée */}
        <div className="mx-auto mt-3 w-10 h-1 rounded-full bg-gray-300" />

        {/* En-tête */}
        <div className="flex items-center gap-3 px-5 pt-3 pb-3">
          <div className="p-2 rounded-xl bg-[#00875a]/10">
            <MessageCircle size={20} className="text-[#00875a]" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="font-extrabold text-[#111111] text-base leading-tight">Conversation</div>
            <div className="text-gray-500 text-xs">Fuite {numeroTag}</div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-full hover:bg-gray-200 transition-colors"
            title="Fermer"
          >
            <X size={20} className="text-[#111111]" />
          </button>
        </div>

        <div className="h-px bg-gray-200" />

        {/* Liste des messages */}
        <div ref={listRef} className="flex-1 overflow-y-auto px-4 py-4 space-y-3">
          {loading ? (
            <div className="h-full flex items-center justify-center">
              <Loader2 size={28} className="text-[#00875a] animate-spin" />
            </div>
          ) : messages.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-center">
              <MessageCircle size={48} className="text-gray-300" />
              <p className="mt-3 text-gray-500 text-sm">Aucun message pour le moment</p>
              <p className="text-gray-400 text-xs mt-1">
                Écrivez un message ou enregistrez un audio
              </p>
            </div>
          ) : (
            messages.map((msg) => {
              const isMe = msg.utilisateurId === myId
              const hasText = !!msg.contenuTexte?.trim()
              const hasAudio = !!msg.cheminAudio?.trim()
              const displayName = msg.nomUtilisateur || 'Utilisateur'
              const initials = displayName.charAt(0).toUpperCase()
              const isPlaying = playingId === msg.id
              const isAudioLoading = audioLoadingId === msg.id

              return (
                <div key={msg.id} className={`flex items-end gap-2 ${isMe ? 'justify-end' : 'justify-start'}`}>
                  {/* Avatar (autres) */}
                  {!isMe && (
                    <div className="w-8 h-8 rounded-full bg-[#00875a] flex items-center justify-center shrink-0">
                      <span className="text-white text-xs font-bold">{initials}</span>
                    </div>
                  )}

                  <div className={`flex flex-col ${isMe ? 'items-end' : 'items-start'} max-w-[78%]`}>
                    {!isMe && displayName && (
                      <span className="text-gray-500 text-[11px] font-semibold mb-0.5 ml-1">{displayName}</span>
                    )}

                    {/* Bulle audio */}
                    {hasAudio && (
                      <button
                        onClick={() => togglePlayPause(msg)}
                        className="flex items-center gap-2 px-3.5 py-2.5 rounded-2xl shadow-sm transition-colors"
                        style={{
                          backgroundColor: isMe ? '#00875a' : '#ffffff',
                          borderBottomLeftRadius: isMe ? 16 : 4,
                          borderBottomRightRadius: isMe ? 4 : 16,
                        }}
                        title="Lecture audio"
                      >
                        {isAudioLoading ? (
                          <Loader2 size={28} className={`animate-spin ${isMe ? 'text-white' : 'text-[#00875a]'}`} />
                        ) : (
                          <>
                            {isPlaying ? (
                              <Pause size={28} className={isMe ? 'text-white' : 'text-[#00875a]'} />
                            ) : (
                              <Play size={28} className={isMe ? 'text-white' : 'text-[#00875a]'} />
                            )}
                          </>
                        )}
                        <AudioWave
                          color={isMe ? '#ffffff' : '#00875a'}
                          progress={isPlaying ? playProgress : 0}
                        />
                        <span className={`text-xs font-medium ${isMe ? 'text-white' : 'text-[#111111]'}`}>
                          {formatDuration(msg.dureeAudioSecondes ?? 0)}
                        </span>
                      </button>
                    )}

                    {/* Bulle texte */}
                    {hasText && (
                      <div
                        className="px-3.5 py-2.5 shadow-sm text-sm"
                        style={{
                          backgroundColor: isMe ? '#00875a' : '#ffffff',
                          color: isMe ? '#ffffff' : '#111111',
                          borderRadius: 16,
                          borderBottomLeftRadius: isMe ? 16 : 4,
                          borderBottomRightRadius: isMe ? 4 : 16,
                          marginTop: hasAudio ? 4 : 0,
                        }}
                      >
                        {msg.contenuTexte}
                      </div>
                    )}

                    {/* Timestamp */}
                    <span className="text-gray-400 text-[10px] mt-0.5 px-1">
                      {formatTime(msg.dateEnvoi)}
                    </span>
                  </div>
                </div>
              )
            })
          )}
        </div>

        {/* Zone de saisie */}
        <div className="bg-white shadow-[0_-2px_10px_rgba(0,0,0,0.05)] px-3 pt-2 pb-4">
          {recording ? (
            <div className="flex items-center gap-3">
              <button
                onClick={cancelRecording}
                className="w-11 h-11 rounded-full bg-gray-200 flex items-center justify-center shrink-0 hover:bg-gray-300 transition-colors"
                title="Annuler"
              >
                <X size={22} className="text-black/60" />
              </button>
              <div className="flex-1 h-11 rounded-full bg-[#F8F9FA] border border-gray-200 flex items-center gap-2 px-4">
                <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
                <div className="flex items-center gap-[3px]">
                  {Array.from({ length: 5 }, (_, i) => (
                    <div
                      key={i}
                      className="w-[3px] rounded-full bg-red-400 animate-pulse"
                      style={{ height: 12 + ((i % 3) + 1) * 6 }}
                    />
                  ))}
                </div>
                <span className="ml-auto text-red-500 font-semibold text-sm">
                  {formatDuration(recordSeconds)}
                </span>
              </div>
              <button
                onClick={stopRecording}
                className="w-11 h-11 rounded-full bg-[#00875a] flex items-center justify-center shrink-0 hover:bg-[#007049] transition-colors"
                title="Envoyer l'audio"
              >
                <Send size={22} className="text-white" />
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <input
                value={text}
                onChange={(e) => setText(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault()
                    void sendText()
                  }
                }}
                placeholder="Écrire un message…"
                className="flex-1 h-11 px-4 rounded-full bg-[#F8F9FA] border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]"
              />
              <button
                onClick={startRecording}
                className="w-11 h-11 rounded-full bg-[#00875a] flex items-center justify-center shrink-0 hover:bg-[#007049] transition-colors"
                title="Enregistrer un audio"
              >
                <Mic size={22} className="text-white" />
              </button>
              <button
                onClick={() => void sendText()}
                disabled={!text.trim() || sending}
                className="w-11 h-11 rounded-full flex items-center justify-center shrink-0 transition-colors disabled:opacity-50"
                style={{ backgroundColor: text.trim() ? '#00875a' : '#e5e7eb' }}
                title="Envoyer"
              >
                {sending ? (
                  <Loader2 size={20} className="text-white animate-spin" />
                ) : (
                  <Send size={20} className={text.trim() ? 'text-white' : 'text-gray-400'} />
                )}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
