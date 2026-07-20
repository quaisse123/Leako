package com.backend.backend.service;

import com.backend.backend.dao.entities.Campagne;
import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.entities.StatutFuite;
import com.backend.backend.dao.repositories.CampagneRepository;
import com.backend.backend.dao.repositories.FuiteRepository;
import com.backend.backend.dto.rapport.FuiteDetailDto;
import com.backend.backend.dto.rapport.FuiteResumeDto;
import com.backend.backend.dto.rapport.RapportResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RapportManager implements RapportService {

    private final FuiteRepository fuiteRepository;
    private final CampagneRepository campagneRepository;

    @Override
    public RapportResponseDto genererRapport(Long utilisateurId, String periode) {
        // 1. Déterminer les bornes de la période
        PeriodeDates dates = calculerPeriode(periode);

        // 2. Récupérer les campagnes de l'utilisateur
        List<Campagne> campagnes = campagneRepository.findByCreateurId(utilisateurId);
        List<Long> campagneIds = campagnes.stream().map(Campagne::getId).toList();

        if (campagneIds.isEmpty()) {
            return creerRapportVide(periode, dates.dateDebut, dates.dateFin);
        }

        // 3. Récupérer toutes les fuites de l'utilisateur
        List<Fuite> toutesLesFuites = fuiteRepository.findByCreateurId(utilisateurId);

        // 4. Filtrer par période
        List<Fuite> fuitesFiltrees = filtrerParPeriode(toutesLesFuites, dates.dateDebut, dates.dateFin);

        // 5. Construire la réponse
        return construireRapport(fuitesFiltrees, campagnes, periode, dates.dateDebut, dates.dateFin);
    }

    @Override
    public RapportResponseDto genererRapportByProjet(Long projetId, String periode) {
        // 1. Déterminer les bornes de la période
        PeriodeDates dates = calculerPeriode(periode);

        // 2. Récupérer les campagnes du projet
        List<Campagne> campagnes = campagneRepository.findByProjetId(projetId);

        if (campagnes.isEmpty()) {
            return creerRapportVide(periode, dates.dateDebut, dates.dateFin);
        }

        // 3. Récupérer toutes les fuites du projet
        List<Fuite> toutesLesFuites = fuiteRepository.findByProjetId(projetId);

        // 4. Filtrer par période
        List<Fuite> fuitesFiltrees = filtrerParPeriode(toutesLesFuites, dates.dateDebut, dates.dateFin);

        // 5. Construire la réponse
        return construireRapport(fuitesFiltrees, campagnes, periode, dates.dateDebut, dates.dateFin);
    }

    // ─── Helpers période ────────────────────────────────────────────

    private record PeriodeDates(Date dateDebut, Date dateFin) {}

    private PeriodeDates calculerPeriode(String periode) {
        LocalDate today = LocalDate.now();
        LocalDate debut = switch (periode) {
            case "1M" -> today.minusMonths(1);
            case "3M" -> today.minusMonths(3);
            case "6M" -> today.minusMonths(6);
            case "1Y" -> today.minusYears(1);
            default -> LocalDate.of(2000, 1, 1);
        };
        Date dateDebut = Date.from(debut.atStartOfDay(ZoneId.systemDefault()).toInstant());
        Date dateFin = Date.from(today.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant());
        return new PeriodeDates(dateDebut, dateFin);
    }

    private List<Fuite> filtrerParPeriode(List<Fuite> fuites, Date dateDebut, Date dateFin) {
        return fuites.stream()
                .filter(f -> !f.getDateDetection().before(dateDebut) && f.getDateDetection().before(dateFin))
                .toList();
    }

    // ─── Construction du rapport ────────────────────────────────────

    private RapportResponseDto construireRapport(
            List<Fuite> fuites,
            List<Campagne> campagnes,
            String periode,
            Date dateDebut,
            Date dateFin
    ) {
        RapportResponseDto r = new RapportResponseDto();

        // Période
        r.setPeriodeLibelle(formaterPeriode(periode));
        r.setDateDebut(dateDebut.toInstant().toString().substring(0, 10));
        r.setDateFin(dateFin.toInstant().toString().substring(0, 10));

        // ── TOP PRIORITY ──
        double coutActives = fuites.stream()
                .filter(f -> f.getStatut() == StatutFuite.A_REPARER || f.getStatut() == StatutFuite.EN_COURS)
                .mapToDouble(f -> f.getCoutAnnuelEstime() != null ? f.getCoutAnnuelEstime() : 0.0)
                .sum();
        double economies = fuites.stream()
                .filter(f -> f.getStatut() == StatutFuite.REPAREE)
                .mapToDouble(f -> f.getCoutAnnuelEstime() != null ? f.getCoutAnnuelEstime() : 0.0)
                .sum();

        r.setCoutFuitesActives(arrondir(coutActives));
        r.setEconomiesRealisees(arrondir(economies));

        // ── NOMBRES ──
        r.setTotalFuites(fuites.size());
        r.setFuitesParCampagne(compterParCampagne(fuites));

        // ── FUITES DÉTAILLÉES PAR CAMPAGNE ──
        r.setFuitesDetailleesParCampagne(groupFuitesByCampagne(fuites));

        // ── PERTES VS ÉCONOMIES PAR CAMPAGNE ──
        r.setPertesParCampagne(calculerPertesParCampagne(fuites));
        r.setEconomiesParCampagne(calculerEconomiesParCampagne(fuites));

        // ── COÛT PAR STATUT ──
        r.setCoutParStatut(calculerCoutParStatut(fuites));

        // ── TAUX DE RÉPARATION ──
        long nbReparees = fuites.stream().filter(f -> f.getStatut() == StatutFuite.REPAREE).count();
        r.setTauxReparationGlobal(fuites.isEmpty() ? 0.0 : arrondir((double) nbReparees / fuites.size() * 100));
        r.setTauxReparationParCampagne(calculerTauxReparationParCampagne(fuites));

        // ── TOP 5 ──
        r.setTop5Actives(classerTop5(fuites, StatutFuite.A_REPARER, StatutFuite.EN_COURS));
        r.setTop5Reparees(classerTop5(fuites, StatutFuite.REPAREE));

        // ── DIAGRAMMES ──
        r.setRepartitionNbrCampagnes(compterParCampagne(fuites));
        r.setRepartitionPertesCampagnes(calculerPertesParCampagne(fuites));
        r.setRepartitionEconomiesCampagnes(calculerEconomiesParCampagne(fuites));

        return r;
    }

    // ─── Méthodes utilitaires ───

    private Map<String, Integer> compterParCampagne(List<Fuite> fuites) {
        Map<String, Integer> map = new LinkedHashMap<>();
        fuites.stream()
                .collect(Collectors.groupingBy(
                        f -> f.getCampagne().getNom(),
                        LinkedHashMap::new,
                        Collectors.summingInt(f -> 1)
                ))
                .forEach((nom, count) -> map.put(nom, count));
        return map;
    }

    private Map<String, List<FuiteDetailDto>> groupFuitesByCampagne(List<Fuite> fuites) {
        Map<String, List<FuiteDetailDto>> map = new LinkedHashMap<>();
        fuites.stream()
                .collect(Collectors.groupingBy(
                        f -> f.getCampagne().getNom(),
                        LinkedHashMap::new,
                        Collectors.toList()
                ))
                .forEach((nom, list) -> {
                    List<FuiteDetailDto> details = list.stream()
                            .map(f -> new FuiteDetailDto(
                                    f.getNumeroTag(),
                                    f.getZone() != null ? f.getZone() : (f.getDescription() != null ? f.getDescription() : ""),
                                    f.getDateDetection() != null
                                            ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm")
                                                    .format(f.getDateDetection())
                                            : ""
                            ))
                            .toList();
                    map.put(nom, details);
                });
        return map;
    }

    private Map<String, Double> calculerPertesParCampagne(List<Fuite> fuites) {
        Map<String, Double> map = new LinkedHashMap<>();
        fuites.stream()
                .filter(f -> f.getStatut() == StatutFuite.A_REPARER || f.getStatut() == StatutFuite.EN_COURS)
                .collect(Collectors.groupingBy(
                        f -> f.getCampagne().getNom(),
                        LinkedHashMap::new,
                        Collectors.summingDouble(f -> f.getCoutAnnuelEstime() != null ? f.getCoutAnnuelEstime() : 0.0)
                ))
                .forEach((nom, val) -> map.put(nom, arrondir(val)));
        return map;
    }

    private Map<String, Double> calculerEconomiesParCampagne(List<Fuite> fuites) {
        Map<String, Double> map = new LinkedHashMap<>();
        fuites.stream()
                .filter(f -> f.getStatut() == StatutFuite.REPAREE)
                .collect(Collectors.groupingBy(
                        f -> f.getCampagne().getNom(),
                        LinkedHashMap::new,
                        Collectors.summingDouble(f -> f.getCoutAnnuelEstime() != null ? f.getCoutAnnuelEstime() : 0.0)
                ))
                .forEach((nom, val) -> map.put(nom, arrondir(val)));
        return map;
    }

    private Map<String, Double> calculerCoutParStatut(List<Fuite> fuites) {
        Map<String, Double> map = new LinkedHashMap<>();
        for (StatutFuite statut : StatutFuite.values()) {
            double total = fuites.stream()
                    .filter(f -> f.getStatut() == statut)
                    .mapToDouble(f -> f.getCoutAnnuelEstime() != null ? f.getCoutAnnuelEstime() : 0.0)
                    .sum();
            map.put(statut.name(), arrondir(total));
        }
        return map;
    }

    private Map<String, Double> calculerTauxReparationParCampagne(List<Fuite> fuites) {
        Map<String, Double> map = new LinkedHashMap<>();
        fuites.stream()
                .collect(Collectors.groupingBy(f -> f.getCampagne().getNom()))
                .forEach((nom, list) -> {
                    long total = list.size();
                    long reparees = list.stream().filter(f -> f.getStatut() == StatutFuite.REPAREE).count();
                    map.put(nom, total == 0 ? 0.0 : arrondir((double) reparees / total * 100));
                });
        return map;
    }

    @SafeVarargs
    private List<FuiteResumeDto> classerTop5(List<Fuite> fuites, StatutFuite... statuts) {
        Set<StatutFuite> statutsSet = Set.of(statuts);
        return fuites.stream()
                .filter(f -> statutsSet.contains(f.getStatut()))
                .filter(f -> f.getCoutAnnuelEstime() != null)
                .sorted(Comparator.comparingDouble(Fuite::getCoutAnnuelEstime).reversed())
                .limit(5)
                .map(f -> new FuiteResumeDto(
                        f.getId(),
                        f.getNumeroTag(),
                        f.getCampagne().getNom(),
                        arrondir(f.getCoutAnnuelEstime()),
                        f.getStatut()
                ))
                .toList();
    }

    private RapportResponseDto creerRapportVide(String periode, Date dateDebut, Date dateFin) {
        RapportResponseDto r = new RapportResponseDto();
        r.setPeriodeLibelle(formaterPeriode(periode));
        r.setDateDebut(dateDebut.toInstant().toString().substring(0, 10));
        r.setDateFin(dateFin.toInstant().toString().substring(0, 10));
        r.setCoutFuitesActives(0.0);
        r.setEconomiesRealisees(0.0);
        r.setTotalFuites(0);
        r.setFuitesParCampagne(new LinkedHashMap<>());
        r.setFuitesDetailleesParCampagne(new LinkedHashMap<>());
        r.setPertesParCampagne(new LinkedHashMap<>());
        r.setEconomiesParCampagne(new LinkedHashMap<>());
        r.setCoutParStatut(new LinkedHashMap<>());
        r.setTauxReparationGlobal(0.0);
        r.setTauxReparationParCampagne(new LinkedHashMap<>());
        r.setTop5Actives(List.of());
        r.setTop5Reparees(List.of());
        r.setRepartitionNbrCampagnes(new LinkedHashMap<>());
        r.setRepartitionPertesCampagnes(new LinkedHashMap<>());
        r.setRepartitionEconomiesCampagnes(new LinkedHashMap<>());
        return r;
    }

    private String formaterPeriode(String periode) {
        return switch (periode) {
            case "1M" -> "Dernier mois";
            case "3M" -> "3 derniers mois";
            case "6M" -> "6 derniers mois";
            case "1Y" -> "Dernière année";
            default -> "Toute la période";
        };
    }

    private double arrondir(double valeur) {
        return Math.round(valeur * 100.0) / 100.0;
    }
}
