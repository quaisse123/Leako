import base64
import json
import os
import re
from io import BytesIO
import cv2  # Bibliothèque de traitement vidéo
import requests
from PIL import Image

# =====================================================================
# 1. CONFIGURATION DE L'API OPENROUTER
# =====================================================================
OPENROUTER_API_KEY = "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"
MODEL_NAME = "google/gemini-2.5-flash"
url = "https://openrouter.ai/api/v1/chat/completions"

# =====================================================================
# 2. CONFIGURATION DU PROMPT EXPERT VIDÉO
# =====================================================================
PROMPT = """
Tu es un expert en maintenance industrielle vapeur dans une usine.
On te fournit une série d'images successives extraites d'une vidéo montrant une fuite.
Analyse la dynamique du fluide (mouvement, débit, écoulement) à travers ces images pour être le plus précis possible.

Classe la fuite selon ces critères stricts :

TYPE DE FUITE :
- liquide : gouttes visibles en mouvement, écoulement, surface mouillée, condensat
- vapeur  : panache blanc/gris diffus, brume, jet gazeux dynamique
- mixte   : présence des deux simultanément

INTENSITE VISUELLE :
- faible  : petite zone, peu visible, suintement léger
- moyenne : zone modérée, fuite active mais contenue  
- forte   : grande zone, fuite importante, jet ou ruissellement rapide

DIAMETRE ESTIME (basé sur l'intensité) :
- faible  → 3mm
- moyenne → 7.5mm
- forte   → 12.5mm
- mixte faible → 5mm
- mixte forte  → 10mm

Réponds UNIQUEMENT avec ce JSON, sans texte avant ou après :
{
  "type_fuite": "liquide" ou "vapeur" ou "mixte",
  "intensite": "faible" ou "moyenne" ou "forte",
  "diametre_mm": 3 ou 5 ou 7.5 ou 10 ou 12.5,
  "confiance": nombre entre 0.0 et 1.0,
  "observation": "une phrase courte en français décrivant la dynamique de la fuite que tu as analysée"
}
"""


# =====================================================================
# 3. FONCTION D'EXTRACTION ET D'ANALYSE DE LA VIDÉO
# =====================================================================
def analyser_video_fuite(chemin_video, max_images_cles=10):
    print(f"🎥 Ouverture de la vidéo : {chemin_video}")

    vidcap = cv2.VideoCapture(chemin_video)
    fps = vidcap.get(cv2.CAP_PROP_FPS)
    total_frames = int(vidcap.get(cv2.CAP_PROP_FRAME_COUNT))

    if total_frames == 0 or fps == 0:
        print("❌ Impossible de lire la vidéo ou fichier corrompu.")
        return None

    intervalle = max(1, int(total_frames / max_images_cles))
    images_encoded = []

    count = 0
    success = True

    print(
        f"⏳ Extraction de {max_images_cles} images clés pour analyser le mouvement..."
    )
    while success:
        success, frame = vidcap.read()
        if not success:
            break

        if count % intervalle == 0 and len(images_encoded) < max_images_cles:
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(frame_rgb)

            tampon = BytesIO()
            img.save(tampon, format="JPEG")
            img_brute = base64.b64encode(tampon.getvalue()).decode("utf-8")
            images_encoded.append(f"data:image/jpeg;base64,{img_brute}")

        count += 1
    vidcap.release()

    contenu_requete = [{"type": "text", "text": PROMPT}]

    for data_url in images_encoded:
        contenu_requete.append(
            {"type": "image_url", "image_url": {"url": data_url}}
        )

    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
    }

    data = {
        "model": MODEL_NAME,
        "messages": [{"role": "user", "content": contenu_requete}],
        "max_tokens": 600,
    }

    print("📡 Envoi de la séquence vidéo à OpenRouter...")
    try:
        response = requests.post(url, headers=headers, json=data)

        if response.status_code == 200:
            result = response.json()

            # LIGNE CORRIGÉE : ajout de [0] pour lire correctement la liste d'OpenRouter
            raw = result["choices"][0]["message"]["content"].strip()
            raw = re.sub(r"```json|```", "", raw).strip()

            analyse_json = json.loads(raw)
            print("\n🎯 [Succès] Analyse de la vidéo terminée :")
            print(json.dumps(analyse_json, indent=2, ensure_ascii=False))
            return analyse_json
        else:
            print(f"❌ Échec de l'API - Code d'erreur : {response.status_code}")
            print(response.text)
            return None

    except Exception as e:
        print(f"❌ Erreur lors du traitement : {e}")
        return None


# =====================================================================
# 4. EXÉCUTION DU TEST
# =====================================================================
nom_video_terrain = "fuite.mp4"

if os.path.exists(nom_video_terrain):
    analyser_video_fuite(nom_video_terrain)
else:
    print(
        f"⚠ Le fichier '{nom_video_terrain}' n'a pas été trouvé. Glissez votre vidéo dans le menu Dossier à gauche."
    )
