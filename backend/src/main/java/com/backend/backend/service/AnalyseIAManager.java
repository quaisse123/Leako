package com.backend.backend.service;

import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.entities.Photo;
import com.backend.backend.dao.repositories.FuiteRepository;
import com.backend.backend.dao.repositories.PhotoRepository;
import com.backend.backend.dto.analyseia.AnalyseIAMediaDto;
import com.backend.backend.dto.analyseia.AnalyseIAReponseDto;
import com.backend.backend.dto.analyseia.AnalyseIAResumeDto;
import com.backend.backend.config.FileStorageConfig;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import net.coobird.thumbnailator.Thumbnails;
import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.Java2DFrameConverter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Path;
import java.util.*;

@Service
@Slf4j
public class AnalyseIAManager implements AnalyseIAService {

    private final PhotoRepository photoRepository;
    private final FuiteRepository fuiteRepository;
    private final FileStorageConfig fileStorageConfig;
    private final ObjectMapper objectMapper;

    // ─── Configuration IA ─────────────────────────────────────────
    // Stratégie : Ollama local (gratuit, illimité) d'abord, puis
    // fallback OpenRouter (si Ollama est arrêté).
    private final String apiKey;
    private final String model;
    private final String openRouterUrl;
    private final String ollamaUrl;

    @Autowired
    public AnalyseIAManager(
            PhotoRepository photoRepository,
            FuiteRepository fuiteRepository,
            FileStorageConfig fileStorageConfig,
            ObjectMapper objectMapper,
            @Value("${openrouter.api-key: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}") String apiKey,
            @Value("${openrouter.model:google/gemini-2.5-flash}") String model,
            @Value("${openrouter.url:https://openrouter.ai/api/v1/chat/completions}") String openRouterUrl,
            @Value("${ollama.url:http://localhost:11434}") String ollamaUrl
    ) {
        this.photoRepository = photoRepository;
        this.fuiteRepository = fuiteRepository;
        this.fileStorageConfig = fileStorageConfig;
        this.objectMapper = objectMapper;
        this.apiKey = apiKey;
        this.model = model;
        this.openRouterUrl = openRouterUrl;
        this.ollamaUrl = ollamaUrl;
    }

    // Modèle Ollama local (vision — analyse d'images/vidéos).
    private static final String OLLAMA_MODEL = "qwen2.5vl:7b";
    // Nombre maximal de tokens de sortie pour Ollama (JSON complet).
    private static final int OLLAMA_NUM_PREDICT = 2000;
    // max_tokens réduit pour le fallback OpenRouter : le solde gratuit
    // restant (~1100 tokens) suffit pour un JSON de 1-2 médias.
    private static final int OPENROUTER_MAX_TOKENS = 1000;
    // Verrou global : une seule analyse IA à la fois pour ne pas
    // saturer la RAM/CPU du VPS (4 CPU, pas de GPU).
    private final java.util.concurrent.Semaphore analyseSemaphore =
            new java.util.concurrent.Semaphore(1);

    // Résolution réduite : le modèle 7B tourne sur CPU (4 cœurs, pas de GPU),
    // des images plus petites accélèrent fortement l'analyse.
    private static final int MAX_DIMENSION = 384;
    private static final int FRAMES_PAR_VIDEO = 3;
    // Timeout HTTP global (OpenRouter). Ollama utilise TIMEOUT_SECONDS + 120.
    private static final int TIMEOUT_SECONDS = 90;

    // ─── Budget d'images pour éviter le timeout ────────────────────
    // Plafond global d'images envoyées à l'IA en un seul appel.
    // Réduit à 8 : le modèle 7B sur CPU est lent, trop d'images = timeout.
    private static final int MAX_IMAGES_TOTAL = 8;
    // Nombre maximal de vidéos analysées (les suivantes sont ignorées).
    private static final int MAX_VIDEOS = 2;

    private static final Set<String> EXTENSIONS_IMAGES = Set.of(".jpg", ".jpeg", ".png", ".webp", ".bmp");
    private static final Set<String> EXTENSIONS_VIDEOS = Set.of(".mp4", ".mov", ".avi", ".mkv", ".3gp");

    // ─── Prompt IA ─────────────────────────────────────────────────
    private static final String PROMPT = """
Tu es un expert en maintenance industrielle vapeur dans une usine.
On te fournit un lot d'images et de sequences de videos melangees representant potentiellement des fuites industrielles.
Chaque media est fourni dans l'ordre exact de son apparition.
IMPORTANT : une video est representee par PLUSIEURS images (frames) consecutives qui appartiennent au MEME media.
Tu dois donc regrouper les frames d'une meme video et fournir UN SEUL resultat par media (photo OU video).

IMPORTANT : Certaines images peuvent ne PAS montrer de fuite, ou etre floues/inutilisables.
Pour chaque media :
- Si aucune fuite n'est clairement visible → mets "fuite_visible": false et ignore les autres champs (null)
- Si une fuite est visible → mets "fuite_visible": true et complete l'analyse

Pour CHAQUE media avec fuite visible, fournis l'analyse selon les criteres suivants :

TYPE DE FUITE — choisis parmi :
- liquide  : gouttes, ecoulement, surface mouillee, condensat
- vapeur   : panache blanc/gris, brume, jet gazeux diffus
- mixte    : liquide et vapeur simultanement

INTENSITE — choisis parmi :
- faible   : suintement, petite zone, peu visible
- moyenne  : fuite active mais contenue, zone moderee
- forte    : jet important, grande zone, tres visible

DIAMETRE ESTIME :
Estimation libre du diametre de l'orifice en millimetres.

CONFIANCE :
Entre 0.0 et 1.0.

Reponds UNIQUEMENT avec un JSON valide sous la forme d'une liste d'objets, sans texte avant ou apres :
[
  {
    "fuite_visible": true,
    "type_fuite": "liquide" ou "vapeur" ou "mixte",
    "intensite": "faible" ou "moyenne" ou "forte",
    "diametre_estime_mm": 4.5,
    "confiance": 0.9,
    "observation": "description visuelle detaillee en francais, max 300 caracteres"
  },
  {
    "fuite_visible": false,
    "type_fuite": null,
    "intensite": null,
    "diametre_estime_mm": null,
    "confiance": 0.0,
    "observation": "Image floue sans fuite identifiable"
  }
]

APRES avoir analyse tous les medias, ajoute UN DERNIER objet de synthese globale :
{
  "synthese": true,
  "observation_globale": "Resume coherent en 1-2 phrases de l'ensemble des fuites observees, max 400 caracteres"
}

La liste finale ressemble donc a :
[
  { analyse media 1... },
  { analyse media 2... },
  { "synthese": true, "observation_globale": "..." }
]
""";

    // ─── Méthode principale ────────────────────────────────────────

    @Override
    public AnalyseIAReponseDto analyserParFuite(Long fuiteId) {
        if (fuiteId == null) {
            throw new IllegalArgumentException("Aucun ID de fuite fourni.");
        }

        List<Photo> photos = photoRepository.findByFuiteId(fuiteId);
        if (photos == null || photos.isEmpty()) {
            throw new IllegalArgumentException("Aucune photo trouvée pour la fuite #" + fuiteId);
        }

        List<MediaPackage> mediasPackages = new ArrayList<>();
        List<String> erreurs = new ArrayList<>();

        // Collecte séparée : vidéos d'abord (plus informatives), photos ensuite.
        List<MediaPackage> imagesPackages = new ArrayList<>();
        List<MediaPackage> videosPackages = new ArrayList<>();
        int videosTraitees = 0;

        for (Photo photo : photos) {
            String filename = photo.getCheminFichier();
            // Nettoyer : enlever le préfixe /uploads/photos/ si présent
            if (filename.startsWith("/uploads/photos/")) {
                filename = filename.substring("/uploads/photos/".length());
            }

            Path filePath = fileStorageConfig.getUploadPath().resolve(filename);
            File file = filePath.toFile();

            if (!file.exists()) {
                erreurs.add("Fichier introuvable : " + filename);
                continue;
            }

            String ext = getExtension(filename).toLowerCase();
            String nom = photo.getCheminFichier();

            try {
                if (EXTENSIONS_IMAGES.contains(ext)) {
                    BufferedImage img = chargerImage(file);
                    if (img != null) {
                        imagesPackages.add(new MediaPackage(nom, List.of(img)));
                    } else {
                        erreurs.add("Impossible de charger l'image : " + filename);
                    }
                } else if (EXTENSIONS_VIDEOS.contains(ext)) {
                    // Limiter le nombre de vidéos analysées pour éviter le timeout.
                    if (videosTraitees >= MAX_VIDEOS) {
                        erreurs.add("Video ignoree (limite de " + MAX_VIDEOS + " videos) : " + filename);
                        continue;
                    }
                    videosTraitees++;
                    List<BufferedImage> frames = extraireFrames(file);
                    if (!frames.isEmpty()) {
                        videosPackages.add(new MediaPackage(nom, frames));
                    } else {
                        erreurs.add("Impossible de lire la video : " + filename);
                    }
                } else {
                    erreurs.add("Format non supporte : " + filename);
                }
            } catch (Exception e) {
                erreurs.add("Erreur lors du traitement de " + filename + " : " + e.getMessage());
            }
        }

        // Priorité : toutes les vidéos (plus informatives), puis les photos, dans la limite du budget global.
        mediasPackages.addAll(videosPackages);
        int budgetRestant = MAX_IMAGES_TOTAL - videosPackages.stream()
                .mapToInt(v -> v.images.size()).sum();
        if (budgetRestant > 0) {
            for (MediaPackage image : imagesPackages) {
                if (budgetRestant <= 0) {
                    erreurs.add("Budget d'images atteint, photo ignoree : " + image.nom);
                    break;
                }
                mediasPackages.add(image);
                budgetRestant -= image.images.size();
            }
        } else if (!imagesPackages.isEmpty()) {
            erreurs.add("Budget d'images atteint (" + MAX_IMAGES_TOTAL + "), photos ignorees.");
        }

        if (mediasPackages.isEmpty()) {
            throw new RuntimeException("Aucun media valide a analyser. " + String.join(" ; ", erreurs));
        }

        // Appel IA — Ollama local d'abord, fallback OpenRouter
        AnalyseIAResultat analyse = appelerIA(mediasPackages);
        List<AnalyseIAMediaDto> resultats = analyse.resultats();

        // Calcul du résumé
        AnalyseIAResumeDto resume = calculerResume(resultats);

        AnalyseIAReponseDto reponse = new AnalyseIAReponseDto();
        reponse.setSuccess(true);
        reponse.setResultats(resultats);
        reponse.setResume(resume);
        reponse.setSynthese(analyse.synthese());
        if (!erreurs.isEmpty()) {
            reponse.setWarnings(erreurs.subList(0, Math.min(5, erreurs.size())));
        }

        // ─── Persistance : dernière réponse IA de la fuite ───
        // On stocke un JSON {photoIds, reponse} pour pouvoir recharger la carte IA
        // et la description à l'ouverture du formulaire, à condition que les photos
        // n'aient pas changé depuis cette analyse.
        try {
            List<Long> photoIds = photos.stream()
                    .map(Photo::getId)
                    .sorted()
                    .toList();
            Map<String, Object> wrapper = new LinkedHashMap<>();
            wrapper.put("photoIds", photoIds);
            wrapper.put("reponse", reponse);
            String json = objectMapper.writeValueAsString(wrapper);

            fuiteRepository.findById(fuiteId).ifPresent(fuite -> {
                fuite.setAnalyseIAJson(json);
                fuiteRepository.save(fuite);
            });
        } catch (Exception e) {
            log.warn("Impossible de persister la reponse IA pour la fuite #{} : {}", fuiteId, e.getMessage());
        }

        return reponse;
    }

    /**
     * Retourne la dernière analyse IA persistée pour une fuite.
     * <p>
     * La réponse n'est renvoyée que si les photos actuelles de la fuite
     * correspondent exactement à celles utilisées lors de l'analyse
     * (comparaison des IDs). Sinon, on retourne {@code null}.
     */
    @Override
    public AnalyseIAReponseDto getDerniereAnalyse(Long fuiteId) {
        if (fuiteId == null) {
            return null;
        }
        try {
            Fuite fuite = fuiteRepository.findById(fuiteId).orElse(null);
            if (fuite == null || fuite.getAnalyseIAJson() == null || fuite.getAnalyseIAJson().isBlank()) {
                return null;
            }

            JsonNode racine = objectMapper.readTree(fuite.getAnalyseIAJson());
            JsonNode photoIdsNode = racine.path("photoIds");
            JsonNode reponseNode = racine.path("reponse");
            if (reponseNode.isMissingNode()) {
                return null;
            }

            // Vérifier que les photos n'ont pas changé depuis l'analyse.
            List<Long> photoIdsPersistes = new ArrayList<>();
            if (photoIdsNode.isArray()) {
                photoIdsNode.forEach(n -> photoIdsPersistes.add(n.asLong()));
            }
            List<Long> photoIdsActuels = photoRepository.findByFuiteId(fuiteId).stream()
                    .map(Photo::getId)
                    .sorted()
                    .toList();
            if (!photoIdsPersistes.equals(photoIdsActuels)) {
                log.info("Photos modifiees pour la fuite #{} — analyse IA ignoree (IDs changes).", fuiteId);
                return null;
            }

            return objectMapper.treeToValue(reponseNode, AnalyseIAReponseDto.class);
        } catch (Exception e) {
            log.warn("Impossible de lire la reponse IA persistee pour la fuite #{} : {}", fuiteId, e.getMessage());
            return null;
        }
    }

    // ─── Traitement des médias ─────────────────────────────────────

    private BufferedImage chargerImage(File file) throws IOException {
        BufferedImage img = ImageIO.read(file);
        if (img == null) return null;
        return Thumbnails.of(img)
                .size(MAX_DIMENSION, MAX_DIMENSION)
                .keepAspectRatio(true)
                .asBufferedImage();
    }

    private List<BufferedImage> extraireFrames(File file) {
        List<BufferedImage> frames = new ArrayList<>();
        try (FFmpegFrameGrabber grabber = new FFmpegFrameGrabber(file)) {
            grabber.start();
            int totalFrames = grabber.getLengthInVideoFrames();
            if (totalFrames <= 0) return frames;

            int intervalle = Math.max(1, totalFrames / FRAMES_PAR_VIDEO);

            try (Java2DFrameConverter converter = new Java2DFrameConverter()) {
                for (int i = 0; i < totalFrames && frames.size() < FRAMES_PAR_VIDEO; i++) {
                    org.bytedeco.javacv.Frame frame = grabber.grabImage();
                    if (frame == null) break;
                    if (i % intervalle == 0) {
                        BufferedImage img = converter.convert(frame);
                        if (img != null) {
                            BufferedImage resized = Thumbnails.of(img)
                                    .size(MAX_DIMENSION, MAX_DIMENSION)
                                    .keepAspectRatio(true)
                                    .asBufferedImage();
                            frames.add(resized);
                        }
                    }
                }
            }
            grabber.stop();
        } catch (Exception e) {
            log.warn("Erreur extraction frames pour {} : {}", file.getName(), e.getMessage());
        }
        return frames;
    }

    private String imageEnBase64(BufferedImage img) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(img, "JPEG", baos);
        return Base64.getEncoder().encodeToString(baos.toByteArray());
    }

    // ─── Appel IA : Ollama local d'abord, fallback OpenRouter ─────

    /**
     * Orchestrateur : tente Ollama local (gratuit, illimité) puis, si
     * indisponible, bascule sur OpenRouter. Un sémaphore garantit qu'une
     * seule analyse tourne à la fois pour ne pas saturer le VPS.
     */
    private AnalyseIAResultat appelerIA(List<MediaPackage> mediasPackages) {
        try {
            analyseSemaphore.acquire();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Analyse IA interrompue : " + e.getMessage());
        }
        try {
            // 1) Ollama local — sans coût, sans limite.
            try {
                return appelerOllama(mediasPackages);
            } catch (Exception eOllama) {
                log.warn("Ollama indisponible ({}), bascule sur OpenRouter.", eOllama.getMessage());
            }
            // 2) Fallback OpenRouter (si Ollama est arrêté).
            return appelerOpenRouter(mediasPackages);
        } finally {
            analyseSemaphore.release();
        }
    }

    /**
     * Appel au modèle local Ollama (vision). Format : POST /api/chat
     * avec les images en base64 dans le message (pas d'image_url).
     */
    private AnalyseIAResultat appelerOllama(List<MediaPackage> mediasPackages) {
        try {
            // Construire le message : texte du prompt + images base64.
            List<String> imagesB64 = new ArrayList<>();
            for (MediaPackage pack : mediasPackages) {
                for (BufferedImage img : pack.images) {
                    imagesB64.add(imageEnBase64(img));
                }
            }

            Map<String, Object> message = new HashMap<>();
            message.put("role", "user");
            message.put("content", PROMPT);
            if (!imagesB64.isEmpty()) {
                message.put("images", imagesB64);
            }

            Map<String, Object> payload = new HashMap<>();
            payload.put("model", OLLAMA_MODEL);
            payload.put("messages", List.of(message));
            payload.put("stream", false);
            // Format JSON strict pour éviter les hallucinations de format.
            payload.put("format", "json");
            payload.put("options", Map.of(
                    "num_predict", OLLAMA_NUM_PREDICT,
                    "temperature", 0.1  // faible → réponses stables, peu d'hallucinations
            ));

            String jsonPayload = objectMapper.writeValueAsString(payload);

            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(java.time.Duration.ofSeconds(10))
                    .build();

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(ollamaUrl + "/api/chat"))
                    .header("Content-Type", "application/json")
                    .timeout(java.time.Duration.ofSeconds(TIMEOUT_SECONDS + 120))
                    .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                log.warn("Erreur Ollama {} : {}", response.statusCode(), response.body());
                throw new RuntimeException("Erreur Ollama (" + response.statusCode() + ")");
            }

            // Réponse Ollama : { "message": { "role", "content" }, "done": true }
            JsonNode root = objectMapper.readTree(response.body());
            String rawContent = root.path("message").path("content").asText("");
            if (rawContent.isBlank()) {
                throw new RuntimeException("Réponse Ollama vide");
            }
            return parserReponseIA(rawContent, mediasPackages);

        } catch (IOException | InterruptedException e) {
            log.error("Erreur appel Ollama : {}", e.getMessage());
            throw new RuntimeException("Erreur de communication avec l'IA locale : " + e.getMessage());
        }
    }

    // ─── Appel OpenRouter (fallback) ───────────────────────────────

    private AnalyseIAResultat appelerOpenRouter(List<MediaPackage> mediasPackages) {
        try {
            // Construire les "parts" : texte + images base64
            List<Map<String, Object>> parts = new ArrayList<>();
            parts.add(Map.of("type", "text", "text", PROMPT));

            for (MediaPackage pack : mediasPackages) {
                for (BufferedImage img : pack.images) {
                    String b64 = imageEnBase64(img);
                    parts.add(Map.of(
                            "type", "image_url",
                            "image_url", Map.of("url", "data:image/jpeg;base64," + b64)
                    ));
                }
            }

            // Payload
            Map<String, Object> message = new HashMap<>();
            message.put("role", "user");
            message.put("content", parts);

            Map<String, Object> payload = new HashMap<>();
            payload.put("model", model);
            payload.put("messages", List.of(message));
            payload.put("max_tokens", OPENROUTER_MAX_TOKENS);
            payload.put("response_format", Map.of("type", "json_object"));

            String jsonPayload = objectMapper.writeValueAsString(payload);

            // Requête HTTP
            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(java.time.Duration.ofSeconds(30))
                    .build();

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(openRouterUrl))
                    .header("Authorization", "Bearer " + apiKey)
                    .header("Content-Type", "application/json")
                    .timeout(java.time.Duration.ofSeconds(TIMEOUT_SECONDS))
                    .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                log.warn("Erreur OpenRouter {} : {}", response.statusCode(), response.body());
                throw new RuntimeException("Erreur API IA (" + response.statusCode() + ")");
            }

            // Parser la réponse
            JsonNode root = objectMapper.readTree(response.body());
            String rawContent = root.get("choices").get(0).get("message").get("content").asText();
            return parserReponseIA(rawContent, mediasPackages);

        } catch (IOException | InterruptedException e) {
            log.error("Erreur appel OpenRouter : {}", e.getMessage());
            throw new RuntimeException("Erreur de communication avec l'IA : " + e.getMessage());
        }
    }

    /**
     * Parse le contenu brut JSON renvoyé par l'IA (Ollama ou OpenRouter),
     * le nettoie, tente une réparation si tronqué, et construit les DTO.
     */
    private AnalyseIAResultat parserReponseIA(String rawContent, List<MediaPackage> mediasPackages) {
        try {
            // Nettoyer les ```json ```
            rawContent = rawContent.replaceAll("```json|```", "").trim();

            JsonNode analysesNode;
            try {
                analysesNode = objectMapper.readTree(rawContent);
            } catch (IOException jsonEx) {
                // Réponse JSON tronquée ou mal formée : tenter une réparation
                // (fermer les chaînes/objets/tableaux ouverts) avant d'abandonner.
                log.warn("JSON IA invalide, tentative de réparation : {}", jsonEx.getMessage());
                String repare = reparerJsonTronque(rawContent);
                analysesNode = objectMapper.readTree(repare);
            }
            List<AnalyseIAMediaDto> resultats = new ArrayList<>();
            String synthese = null;

            if (analysesNode.isArray()) {
                int mediaIndex = 0;
                for (int i = 0; i < analysesNode.size(); i++) {
                    JsonNode item = analysesNode.get(i);
                    // Objet de synthèse globale : à exclure des résultats par média.
                    if (item.has("synthese") && item.get("synthese").asBoolean(false)) {
                        synthese = item.has("observation_globale")
                                ? item.get("observation_globale").asText()
                                : null;
                        continue;
                    }
                    resultats.add(analyserJsonEnDto(item, mediaIndex < mediasPackages.size() ? mediasPackages.get(mediaIndex).nom : "media_" + mediaIndex));
                    mediaIndex++;
                }
            } else if (analysesNode.isObject()) {
                if (analysesNode.has("synthese") && analysesNode.get("synthese").asBoolean(false)) {
                    synthese = analysesNode.has("observation_globale")
                            ? analysesNode.get("observation_globale").asText()
                            : null;
                } else {
                    resultats.add(analyserJsonEnDto(analysesNode, mediasPackages.get(0).nom));
                }
            }

            // Stocker la synthèse pour la réponse finale.
            return new AnalyseIAResultat(resultats, synthese);

        } catch (IOException e) {
            log.error("Erreur parsing réponse IA : {}", e.getMessage());
            throw new RuntimeException("Réponse IA illisible : " + e.getMessage());
        }
    }

    private AnalyseIAMediaDto analyserJsonEnDto(JsonNode item, String nomFichier) {
        boolean fuiteVisible = item.has("fuite_visible") && item.get("fuite_visible").asBoolean(true);

        String typeFuite = fuiteVisible && item.has("type_fuite") ? item.get("type_fuite").asText() : null;
        String intensite = fuiteVisible && item.has("intensite") ? item.get("intensite").asText() : null;
        double diametre = fuiteVisible && item.has("diametre_estime_mm") ? item.get("diametre_estime_mm").asDouble() : 0.0;
        double confiance = item.has("confiance") ? item.get("confiance").asDouble() : 0.0;
        String observation = item.has("observation") ? item.get("observation").asText() : "";

        if (fuiteVisible) {
            // Clamp — plage du slider (1.0 - 50.0)
            diametre = Math.max(1.0, Math.min(50.0, diametre));
            confiance = Math.max(0.0, Math.min(1.0, confiance));
        }

        return new AnalyseIAMediaDto(nomFichier, fuiteVisible, typeFuite, intensite, diametre, confiance, observation);
    }

    // ─── Résumé ────────────────────────────────────────────────────

    private AnalyseIAResumeDto calculerResume(List<AnalyseIAMediaDto> resultats) {
        // Filtrer uniquement les médias avec fuite visible
        List<AnalyseIAMediaDto> avecFuite = resultats.stream()
                .filter(AnalyseIAMediaDto::isFuiteVisible)
                .toList();

        if (avecFuite.isEmpty()) {
            // Aucun média ne montre de fuite clairement
            return new AnalyseIAResumeDto("inconnu", "inconnue", 0.0, 0.0);
        }

        // Type majoritaire
        Map<String, Integer> typeCount = new HashMap<>();
        for (var r : avecFuite) {
            typeCount.merge(r.getTypeFuite(), 1, Integer::sum);
        }
        String typeFuite = typeCount.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("vapeur");

        // Intensité moyenne
        Map<String, Integer> ordre = Map.of("faible", 0, "moyenne", 1, "forte", 2);
        double intensiteSum = avecFuite.stream()
                .mapToInt(r -> ordre.getOrDefault(r.getIntensite(), 1))
                .sum();
        int intensiteMoy = (int) Math.round(intensiteSum / avecFuite.size());
        String intensite = List.of("faible", "moyenne", "forte")
                .get(Math.min(2, Math.max(0, intensiteMoy)));

        // Diamètre moyen — pondéré par la confiance
        double diametreNumerateur = 0, denominateur = 0;
        for (var r : avecFuite) {
            diametreNumerateur += r.getDiametreEstimeMm() * r.getConfiance();
            denominateur += r.getConfiance();
        }
        double diametreMoyen = denominateur > 0
                ? Math.round((diametreNumerateur / denominateur) * 10.0) / 10.0
                : 0.0;

        // Confiance moyenne
        double confianceMoy = avecFuite.stream()
                .mapToDouble(AnalyseIAMediaDto::getConfiance)
                .average()
                .orElse(0.0);
        confianceMoy = Math.round(confianceMoy * 100.0) / 100.0;

        return new AnalyseIAResumeDto(typeFuite, intensite, diametreMoyen, confianceMoy);
    }

    // ─── Helpers ───────────────────────────────────────────────────

    private String getExtension(String filename) {
        int lastDot = filename.lastIndexOf('.');
        return (lastDot == -1) ? "" : filename.substring(lastDot);
    }

    // ─── Réparation de JSON tronqué ────────────────────────────────

    /**
     * Tente de réparer un JSON tronqué (réponse IA coupée par max_tokens).
     * Ferme les chaînes, objets et tableaux restés ouverts, et ajoute les
     * virgules manquantes. Retourne le JSON réparé, ou l'entrée inchangée
     * si aucune réparation n'est possible.
     */
    private String reparerJsonTronque(String json) {
        if (json == null || json.isBlank()) {
            return json;
        }
        StringBuilder sb = new StringBuilder(json.trim());
        Deque<Character> pile = new ArrayDeque<>();
        boolean dansChaine = false;
        boolean echappe = false;

        // Parcourir pour détecter l'état final (chaîne/objet/tableau ouverts).
        for (int i = 0; i < sb.length(); i++) {
            char c = sb.charAt(i);
            if (dansChaine) {
                if (echappe) {
                    echappe = false;
                } else if (c == '\\') {
                    echappe = true;
                } else if (c == '"') {
                    dansChaine = false;
                }
                continue;
            }
            switch (c) {
                case '"' -> dansChaine = true;
                case '{', '[' -> pile.push(c);
                case '}', ']' -> {
                    if (!pile.isEmpty()) {
                        pile.pop();
                    }
                }
                default -> { /* ignorer */ }
            }
        }

        // Si une chaîne est restée ouverte, la fermer.
        if (dansChaine) {
            sb.append('"');
        }

        // Fermer les objets/tableaux ouverts, dans l'ordre inverse.
        while (!pile.isEmpty()) {
            char ouvert = pile.pop();
            // Ajouter une virgule avant la fermeture si le dernier caractère
            // non-espace n'est pas déjà une virgule ou un ouvrant.
            char dernier = dernierNonEspace(sb);
            if (dernier != ',' && dernier != '{' && dernier != '[') {
                sb.append(',');
            }
            sb.append(ouvert == '{' ? '}' : ']');
        }

        return sb.toString();
    }

    private char dernierNonEspace(StringBuilder sb) {
        for (int i = sb.length() - 1; i >= 0; i--) {
            char c = sb.charAt(i);
            if (!Character.isWhitespace(c)) {
                return c;
            }
        }
        return '\0';
    }

    // ─── Classe interne ────────────────────────────────────────────

    private record MediaPackage(String nom, List<BufferedImage> images) {}

    private record AnalyseIAResultat(List<AnalyseIAMediaDto> resultats, String synthese) {}
}
