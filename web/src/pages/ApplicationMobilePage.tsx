import { QRCodeSVG } from 'qrcode.react'
import { Smartphone, Download, RefreshCw, CheckCircle2 } from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'

/**
 * Application Mobile — QR code + lien de téléchargement de l'APK.
 * Le fichier APK est servi statiquement par nginx sous /apk/leaks-survey.apk.
 */
export default function ApplicationMobilePage() {
  const apkUrl = `${window.location.origin}/apk/leaks-survey.apk`

  return (
    <Layout>
      <div className="max-w-3xl mx-auto px-6 py-8">
        <PageHeader
          title="Application Mobile"
          subtitle="Scannez le QR code pour télécharger et installer l'application sur votre téléphone."
        />

        <div className="bg-white rounded-2xl border border-[#e5e7eb] p-8">
          <div className="flex flex-col md:flex-row items-center gap-8">
            {/* QR Code */}
            <div className="flex flex-col items-center gap-3">
              <div className="bg-white p-4 rounded-2xl border border-[#e5e7eb] shadow-sm">
                <QRCodeSVG
                  value={apkUrl}
                  size={220}
                  level="M"
                  marginSize={2}
                  fgColor="#111111"
                  bgColor="#ffffff"
                />
              </div>
              <div className="flex items-center gap-2 text-sm text-[#757575]">
                <Smartphone size={16} className="text-[#00875a]" />
                <span>Scannez avec votre téléphone</span>
              </div>
            </div>

            {/* Infos + téléchargement */}
            <div className="flex-1 w-full">
              <h2 className="text-lg font-bold text-[#111111] mb-2">
                Télécharger l'application
              </h2>
              <p className="text-sm text-[#757575] mb-4">
                L'application mobile OCP Leaks permet de déclarer les fuites
                directement sur le terrain, avec prise de photos et analyse IA.
              </p>

              <div className="space-y-2 mb-6">
                <div className="flex items-center gap-2 text-sm text-[#111111]">
                  <CheckCircle2 size={16} className="text-[#00875a] flex-shrink-0" />
                  <span>Version Android (APK)</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-[#111111]">
                  <CheckCircle2 size={16} className="text-[#00875a] flex-shrink-0" />
                  <span>Installation hors Play Store</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-[#111111]">
                  <CheckCircle2 size={16} className="text-[#00875a] flex-shrink-0" />
                  <span>
                    Une fois téléchargé, autorisez l'installation depuis des
                    sources inconnues.
                  </span>
                </div>
              </div>

              <div className="flex flex-wrap gap-3">
                <a
                  href={apkUrl}
                  download
                  className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-[#00875a] text-white font-semibold text-sm hover:bg-[#007049] transition-colors"
                >
                  <Download size={18} />
                  Télécharger l'APK
                </a>
                <button
                  onClick={() => window.location.reload()}
                  className="inline-flex items-center gap-2 px-5 py-3 rounded-xl border border-[#e5e7eb] text-[#757575] font-medium text-sm hover:bg-[#f5f5f5] transition-colors"
                >
                  <RefreshCw size={16} />
                  Actualiser
                </button>
              </div>

              <div className="mt-6 pt-4 border-t border-[#e5e7eb]">
                <p className="text-xs text-[#9ca3af]">
                  Lien direct :{' '}
                  <a
                    href={apkUrl}
                    className="text-[#00875a] hover:underline break-all"
                  >
                    {apkUrl}
                  </a>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  )
}
