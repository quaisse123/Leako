package com.backend.backend.service;

import com.backend.backend.dto.rapport.RapportResponseDto;

public interface RapportService {

    /**
     * Génère le rapport complet pour un utilisateur sur une période donnée.
     *
     * @param utilisateurId ID de l'utilisateur
     * @param periode       Code période : "1M", "3M", "6M", "1Y", "ALL"
     * @return RapportResponseDto contenant toutes les métriques calculées
     */
    RapportResponseDto genererRapport(Long utilisateurId, String periode);

    /**
     * Génère le rapport complet pour un projet sur une période donnée.
     * Tous les membres du projet voient les mêmes données.
     *
     * @param projetId ID du projet
     * @param periode  Code période : "1M", "3M", "6M", "1Y", "ALL"
     * @return RapportResponseDto contenant toutes les métriques calculées
     */
    RapportResponseDto genererRapportByProjet(Long projetId, String periode);
}
