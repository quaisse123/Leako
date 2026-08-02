package com.backend.backend.service;

import com.backend.backend.dto.analyseia.AnalyseIAReponseDto;

public interface AnalyseIAService {
    AnalyseIAReponseDto analyserParFuite(Long fuiteId);

    /**
     * Retourne la dernière analyse IA persistée pour une fuite,
     * si elle existe et si les photos n'ont pas changé depuis.
     * Retourne {@code null} si aucune analyse ou si les photos ont changé.
     */
    AnalyseIAReponseDto getDerniereAnalyse(Long fuiteId);
}
