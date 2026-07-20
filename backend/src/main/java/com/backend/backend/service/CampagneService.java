package com.backend.backend.service;

import com.backend.backend.dto.campagne.CampagneRequestDto;
import com.backend.backend.dto.campagne.CampagnePatchDto;
import com.backend.backend.dto.campagne.CampagneResponseDto;
import java.util.List;

public interface CampagneService {

    CampagneResponseDto createCampagne(CampagneRequestDto dto);

    CampagneResponseDto updateCampagne(Long id, CampagneRequestDto dto);

    CampagneResponseDto patchCampagne(Long id, CampagnePatchDto dto);

    void deleteCampagne(Long id);

    List<CampagneResponseDto> getAllCampagnes();

    CampagneResponseDto getCampagneById(Long id);

    List<CampagneResponseDto> getCampagnesByUtilisateur(Long utilisateurId);

    List<CampagneResponseDto> getCampagnesByProjetId(Long projetId);
}
