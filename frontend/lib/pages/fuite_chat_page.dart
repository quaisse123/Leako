// 💬 Chat Fuite — Bottom modal de conversation autour d'une fuite
// Messages texte + audio (enregistrement façon WhatsApp)

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../models/fuite_message.dart';
import '../api/fuite_message_api.dart' as message_api;
import '../api/api_config.dart';
import '../api/jwt_service.dart';

class FuiteChatPage extends StatefulWidget {
  final int fuiteId;
  final String numeroTag;
  final int utilisateurId;

  const FuiteChatPage({
    super.key,
    required this.fuiteId,
    required this.numeroTag,
    required this.utilisateurId,
  });

  @override
  State<FuiteChatPage> createState() => _FuiteChatPageState();
}

class _FuiteChatPageState extends State<FuiteChatPage>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _audioRecorder = AudioRecorder();
  List<FuiteMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  // Enregistrement audio
  bool _isRecording = false;
  String? _audioPath;
  int _recordDuration = 0;
  late AnimationController _pulseAnim;

  // Lecture audio
  final _audioPlayer = AudioPlayer();
  int? _playingMessageId;
  double _playProgress = 0.0;
  bool _audioLoading = false;
  StreamSubscription<dynamic>? _posSub;
  StreamSubscription<dynamic>? _completeSub;
  StreamSubscription<dynamic>? _errorSub;
  final Map<int, String> _audioCache = {};

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadMessages();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _completeSub?.cancel();
    _errorSub?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  /// Joue ou met en pause un message audio (téléchargement + cache local).
  Future<void> _togglePlayPause(FuiteMessage msg) async {
    if (_audioLoading) return;

    // Même message → toggle play/pause
    if (_playingMessageId == msg.id) {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      return;
    }

    // Nouveau message : arrêter l'ancien + nettoyer les anciens listeners
    await _audioPlayer.stop();
    _posSub?.cancel();
    _completeSub?.cancel();
    _errorSub?.cancel();
    _posSub = null;
    _completeSub = null;
    _errorSub = null;

    setState(() {
      _playingMessageId = msg.id;
      _playProgress = 0.0;
      _audioLoading = true;
    });

    try {
      // 1. Obtenir le chemin local (cache ou téléchargement)
      String localPath;
      if (_audioCache.containsKey(msg.id)) {
        localPath = _audioCache[msg.id]!;
        debugPrint('📂 Audio depuis cache: $localPath');
      } else {
        final baseUrl = ApiConfig.apiBaseUrl.replaceFirst('/api', '');
        final url = '$baseUrl/${msg.cheminAudio}';
        debugPrint('⬇️ Téléchargement audio: $url');

        final headers = await authHeaders();
        // On enlève Content-Type pour un download binaire
        headers.remove('Content-Type');
        final client = http.Client();
        final response = await client
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 15));
        client.close();

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }

        final dir = await getTemporaryDirectory();
        localPath = '${dir.path}/audio_${msg.id}.m4a';
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        _audioCache[msg.id] = localPath;
        debugPrint(
          '✅ Audio téléchargé: $localPath (${response.bodyBytes.length} bytes)',
        );
      }

      // 2. Configurer les listeners UNE SEULE FOIS
      _posSub = _audioPlayer.onPositionChanged.listen((pos) {
        if (!mounted) return;
        _audioPlayer.getDuration().then((dur) {
          if (dur != null && dur.inMilliseconds > 0 && mounted) {
            setState(() {
              _playProgress = pos.inMilliseconds / dur.inMilliseconds;
            });
          }
        });
      });

      _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
        debugPrint('✅ Lecture terminée');
        if (!mounted) return;
        setState(() {
          _playingMessageId = null;
          _playProgress = 0.0;
          _audioLoading = false;
        });
      });

      // Écoute des erreurs via eventStream (API audioplayers 6.x)
      _errorSub = _audioPlayer.eventStream.listen(
        (event) {
          // Les erreurs sont propagées via addError sur le controller
        },
        onError: (Object error) {
          debugPrint('❌ Erreur lecture audio: $error');
          if (!mounted) return;
          setState(() {
            _playingMessageId = null;
            _playProgress = 0.0;
            _audioLoading = false;
          });
        },
      );

      // 3. Lancer la lecture
      await _audioPlayer.play(DeviceFileSource(localPath));
      setState(() => _audioLoading = false);
      debugPrint('▶️ Lecture démarrée: $localPath');
    } catch (e) {
      debugPrint('❌ Échec lecture audio: $e');
      if (mounted) {
        setState(() {
          _playingMessageId = null;
          _playProgress = 0.0;
          _audioLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await message_api.getMessagesByFuite(widget.fuiteId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _textCtrl.clear();

    try {
      await message_api.createTextMessage(
        fuiteId: widget.fuiteId,
        utilisateurId: widget.utilisateurId,
        contenuTexte: text,
      );
      await _loadMessages();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  // ─── Enregistrement audio (façon WhatsApp) ─────────────

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission micro requise')),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _audioPath = path;

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _pulseAnim.repeat(reverse: true);
      setState(() => _isRecording = true);

      // Timer pour suivre la durée
      _recordDuration = 0;
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!_isRecording) return false;
        _recordDuration++;
        if (mounted) setState(() {});
        return true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur d\'enregistrement: $e')));
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _pulseAnim.stop();
    _pulseAnim.reset();
    setState(() => _isRecording = false);

    try {
      final path = await _audioRecorder.stop();
      if (path != null && File(path).existsSync()) {
        _audioPath = path;
        await _sendAudio();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _sendAudio() async {
    if (_audioPath == null || _sending) return;
    setState(() => _sending = true);

    try {
      await message_api.createAudioMessage(
        fuiteId: widget.fuiteId,
        utilisateurId: widget.utilisateurId,
        audioFile: File(_audioPath!),
        dureeAudioSecondes: _recordDuration,
      );
      _audioPath = null;
      _recordDuration = 0;
      await _loadMessages();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Poignée de tirage ──
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── En-tête ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00875A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat_rounded,
                    color: Color(0xFF00875A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conversation',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF111111),
                        ),
                      ),
                      Text(
                        'Fuite ${widget.numeroTag}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Liste des messages ──
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00875A)),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun message pour le moment',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Écrivez un message ou enregistrez un audio',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.utilisateurId == widget.utilisateurId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          // ── Zone de saisie ──
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _isRecording ? _buildRecordingBar() : _buildTextInputBar(),
    );
  }

  Widget _buildRecordingBar() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Row(
          children: [
            // Bouton annuler
            GestureDetector(
              onTap: () async {
                _pulseAnim.stop();
                _pulseAnim.reset();
                setState(() => _isRecording = false);
                await _audioRecorder.stop();
                if (_audioPath != null && File(_audioPath!).existsSync()) {
                  File(_audioPath!).deleteSync();
                }
                _audioPath = null;
                _recordDuration = 0;
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.black54,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Vague sonore animée + durée
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Icône micro animée (pulse)
                    Icon(
                      Icons.mic,
                      color: Colors.red.withValues(
                        alpha: 0.5 + (_pulseAnim.value * 0.5),
                      ),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    // Barres de son simulées
                    ...List.generate(
                      5,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3,
                        height: 12 + (_pulseAnim.value * 12 * ((i % 3) + 1)),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(_recordDuration),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Bouton envoyer l'audio
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00875A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextInputBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _textCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
              decoration: InputDecoration(
                hintText: 'Écrire un message…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Bouton micro (enregistrement)
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00875A),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.mic_none_rounded, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        // Bouton envoyer texte
        GestureDetector(
          onTap: _sending ? null : _sendText,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _textCtrl.text.trim().isEmpty
                  ? Colors.grey[200]
                  : const Color(0xFF00875A),
              borderRadius: BorderRadius.circular(22),
            ),
            child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(FuiteMessage msg, bool isMe) {
    final hasText = msg.contenuTexte != null && msg.contenuTexte!.isNotEmpty;
    final hasAudio = msg.cheminAudio != null && msg.cheminAudio!.isNotEmpty;
    final displayName = msg.nomUtilisateur ?? 'Utilisateur';
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar (caché pour l'expéditeur "moi")
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF00875A),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Contenu du message
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Nom de l'utilisateur (pour les autres)
                  if (!isMe && displayName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, left: 4),
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Bulle audio (comme WhatsApp)
                  if (hasAudio)
                    GestureDetector(
                      onTap: () => _togglePlayPause(msg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF00875A) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icône play/pause (ou spinner si chargement)
                            _audioLoading && _playingMessageId == msg.id
                                ? SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF00875A),
                                    ),
                                  )
                                : Icon(
                                    _playingMessageId == msg.id &&
                                            _audioPlayer.state ==
                                                PlayerState.playing
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_filled_rounded,
                                    size: 28,
                                    color: isMe
                                        ? Colors.white
                                        : const Color(0xFF00875A),
                                  ),
                            const SizedBox(width: 8),
                            // Ligne de son avec progression
                            SizedBox(
                              width: 80,
                              height: 24,
                              child: CustomPaint(
                                size: const Size(80, 24),
                                painter: _AudioWavePainter(
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : const Color(
                                          0xFF00875A,
                                        ).withValues(alpha: 0.6),
                                  progress: _playingMessageId == msg.id
                                      ? _playProgress
                                      : 0.0,
                                  progressColor: isMe
                                      ? Colors.white
                                      : const Color(0xFF00875A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(msg.dureeAudioSecondes ?? 0),
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : const Color(0xFF111111),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Bulle texte (si présent avec l'audio ou seul)
                  if (hasText)
                    Container(
                      margin: hasAudio
                          ? const EdgeInsets.only(top: 4)
                          : EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF00875A) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        msg.contenuTexte!,
                        style: TextStyle(
                          color: isMe ? Colors.white : const Color(0xFF111111),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                    child: Text(
                      _formatTime(msg.dateEnvoi),
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Paint personnalisé pour la vague audio ─────────────
class _AudioWavePainter extends CustomPainter {
  final Color color;
  final double progress;
  final Color progressColor;

  _AudioWavePainter({
    required this.color,
    this.progress = 0.0,
    this.progressColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 20;
    final spacing = size.width / barCount;
    final progressIndex = barCount * progress;

    for (int i = 0; i < barCount; i++) {
      final isPlayed = i <= progressIndex;
      final paint = Paint()
        ..color = isPlayed ? progressColor : color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final height = 4.0 + (i % 5) * 3.0;
      final x = i * spacing + spacing / 2;
      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AudioWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
