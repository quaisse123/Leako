package com.backend.backend.dto.rapport;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RapportResponseDto {

    // Période
    private String periodeLibelle;
    private String dateDebut;
    private String dateFin;

    // ── TOP PRIORITY ──
    private Double coutFuitesActives;   // MAD
    private Double economiesRealisees;  // MAD

    // ── NOMBRES ──
    private Integer totalFuites;
    private Map<String, Integer> fuitesParCampagne;

    // ── FUITES DÉTAILLÉES PAR CAMPAGNE ──
    private Map<String, List<FuiteDetailDto>> fuitesDetailleesParCampagne;

    // ── PERTES VS ÉCONOMIES PAR CAMPAGNE ──
    private Map<String, Double> pertesParCampagne;
    private Map<String, Double> economiesParCampagne;

    // ── COÛT PAR STATUT ──
    private Map<String, Double> coutParStatut;

    // ── TAUX DE RÉPARATION ──
    private Double tauxReparationGlobal;
    private Map<String, Double> tauxReparationParCampagne;

    // ── TOP 5 ──
    private List<FuiteResumeDto> top5Actives;
    private List<FuiteResumeDto> top5Reparees;

    // ── DIAGRAMMES (par campagne) ──
    private Map<String, Integer> repartitionNbrCampagnes;
    private Map<String, Double> repartitionPertesCampagnes;
    private Map<String, Double> repartitionEconomiesCampagnes;
}
