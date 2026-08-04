package com.backend.backend.web;

import com.backend.backend.dto.analyseia.AnalyseIAReponseDto;
import com.backend.backend.service.AnalyseIAService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@CrossOrigin
@RestController
@RequestMapping("/api/analyse-ia")
@RequiredArgsConstructor
public class AnalyseIAController {

    private final AnalyseIAService analyseIAService;

    @PostMapping
    public ResponseEntity<?> analyser(@RequestBody Map<String, Long> body) {
        Long fuiteId = body.get("fuiteId");
        if (fuiteId == null) {
            return ResponseEntity.badRequest().build();
        }

        try {
            AnalyseIAReponseDto reponse = analyseIAService.analyserParFuite(fuiteId);
            return ResponseEntity.ok(reponse);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            // Message convivial pour l'utilisateur (le détail technique reste en log).
            return ResponseEntity.internalServerError()
                    .body(Map.of("message", "Une erreur est survenue lors de l'analyse IA. Veuillez réessayer plus tard."));
        }
    }

    /**
     * Retourne la dernière analyse IA persistée pour une fuite (204 si aucune
     * analyse à jour — les photos ont changé ou aucune analyse n'a été faite).
     */
    @GetMapping("/{fuiteId}")
    public ResponseEntity<AnalyseIAReponseDto> getDerniereAnalyse(@PathVariable Long fuiteId) {
        try {
            AnalyseIAReponseDto reponse = analyseIAService.getDerniereAnalyse(fuiteId);
            if (reponse == null) {
                return ResponseEntity.noContent().build();
            }
            return ResponseEntity.ok(reponse);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }
}
