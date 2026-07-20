package com.backend.backend.web;

import com.backend.backend.dto.rapport.RapportResponseDto;
import com.backend.backend.service.PdfExportService;
import com.backend.backend.service.RapportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Set;

@CrossOrigin
@RestController
@RequestMapping("/api/rapports")
@RequiredArgsConstructor
public class RapportController {

    private final RapportService rapportService;
    private final PdfExportService pdfExportService;

    /**
     * Génère le rapport complet pour un utilisateur sur une période donnée.
     *
     * @param utilisateurId ID de l'utilisateur
     * @param periode       Code période : "1M", "3M", "6M", "1Y", "ALL"
     * @return RapportResponseDto avec toutes les métriques calculées
     */
    @GetMapping
    public ResponseEntity<RapportResponseDto> getRapport(
            @RequestParam Long utilisateurId,
            @RequestParam(defaultValue = "ALL") String periode
    ) {
        RapportResponseDto rapport = rapportService.genererRapport(utilisateurId, periode);
        return ResponseEntity.ok(rapport);
    }

    /**
     * Génère le rapport complet pour un projet sur une période donnée.
     * Tous les membres voient les mêmes données centralisées.
     *
     * @param projetId ID du projet
     * @param periode  Code période : "1M", "3M", "6M", "1Y", "ALL"
     * @return RapportResponseDto avec toutes les métriques calculées
     */
    @GetMapping("/projet")
    public ResponseEntity<RapportResponseDto> getRapportByProjet(
            @RequestParam Long projetId,
            @RequestParam(defaultValue = "ALL") String periode
    ) {
        RapportResponseDto rapport = rapportService.genererRapportByProjet(projetId, periode);
        return ResponseEntity.ok(rapport);
    }

    /**
     * Télécharge le rapport PDF personnalisé pour un projet.
     *
     * @param projetId ID du projet
     * @param periode  Code période : "1M", "3M", "6M", "1Y", "ALL"
     * @param metrics  Liste d'IDs de métriques séparés par des virgules (optionnel, défaut = toutes)
     * @return Fichier PDF à télécharger
     */
    @GetMapping("/projet/pdf")
    public ResponseEntity<byte[]> downloadPdf(
            @RequestParam Long projetId,
            @RequestParam(defaultValue = "ALL") String periode,
            @RequestParam(required = false) Set<String> metrics
    ) {
        byte[] pdfBytes = pdfExportService.genererPdf(projetId, periode, metrics);

        String filename = "rapport-ocp-projet-" + projetId + "-" + periode + ".pdf";

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .contentLength(pdfBytes.length)
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .body(pdfBytes);
    }
}
