package com.backend.backend.service;

import com.backend.backend.dto.fuite.FuiteRequestDto;
import com.backend.backend.dto.fuite.FuiteResponseDto;
import java.util.List;

public interface FuiteService {

    FuiteResponseDto createFuite(FuiteRequestDto dto);

    FuiteResponseDto updateFuite(Long id, FuiteRequestDto dto);

    void deleteFuite(Long id);

    List<FuiteResponseDto> getAllFuites();

    FuiteResponseDto getFuiteById(Long id);

    List<FuiteResponseDto> getFuitesByCampagne(Long campagneId);

    List<FuiteResponseDto> getFuitesByUtilisateur(Long utilisateurId);

    List<FuiteResponseDto> getFuitesByProjetId(Long projetId);

    String genererProchainTag(String campagneNom, Long campagneId);
}
