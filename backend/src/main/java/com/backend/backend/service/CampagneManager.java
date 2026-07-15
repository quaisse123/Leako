package com.backend.backend.service;

import com.backend.backend.dao.entities.Campagne;
import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dao.repositories.CampagneRepository;
import com.backend.backend.dao.repositories.UtilisateurRepository;
import com.backend.backend.dto.campagne.CampagneRequestDto;
import com.backend.backend.dto.campagne.CampagnePatchDto;
import com.backend.backend.dto.campagne.CampagneResponseDto;
import com.backend.backend.mapper.CampagneMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CampagneManager implements CampagneService {

    private final CampagneRepository campagneRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final CampagneMapper campagneMapper;

    @Override
    public CampagneResponseDto createCampagne(CampagneRequestDto dto) {
        Campagne campagne = campagneMapper.toEntity(dto);

        // Initialise la date de création avec l'heure courante
        campagne.setDateCreation(new Date());

        // Associe le créateur
        if (dto.getCreateurId() != null) {
            Utilisateur createur = utilisateurRepository.findById(dto.getCreateurId())
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé avec l'ID : " + dto.getCreateurId()));
            campagne.setCreateur(createur);
        }

        campagne = campagneRepository.save(campagne);
        return campagneMapper.toDto(campagne);
    }

    @Override
    public CampagneResponseDto updateCampagne(Long id, CampagneRequestDto dto) {
        Campagne campagne = campagneRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Campagne non trouvée avec l'ID : " + id));

        campagne.setNom(dto.getNom());
        campagne.setDescription(dto.getDescription());
        campagne.setZone(dto.getZone());
        campagne.setEstCloturee(dto.getEstCloturee() != null ? dto.getEstCloturee() : false);

        campagne = campagneRepository.save(campagne);
        return campagneMapper.toDto(campagne);
    }

    @Override
    public CampagneResponseDto patchCampagne(Long id, CampagnePatchDto dto) {
        Campagne campagne = campagneRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Campagne non trouvée avec l'ID : " + id));

        if (dto.getNom() != null) campagne.setNom(dto.getNom());
        if (dto.getDescription() != null) campagne.setDescription(dto.getDescription());
        if (dto.getZone() != null) campagne.setZone(dto.getZone());
        if (dto.getEstCloturee() != null) campagne.setEstCloturee(dto.getEstCloturee());

        campagne = campagneRepository.save(campagne);
        return campagneMapper.toDto(campagne);
    }

    @Override
    public void deleteCampagne(Long id) {
        if (!campagneRepository.existsById(id)) {
            throw new RuntimeException("Campagne non trouvée avec l'ID : " + id);
        }
        campagneRepository.deleteById(id);
    }

    @Override
    public List<CampagneResponseDto> getAllCampagnes() {
        return campagneRepository.findAll().stream()
            .map(campagneMapper::toDto)
            .collect(Collectors.toList());
    }

    @Override
    public CampagneResponseDto getCampagneById(Long id) {
        Campagne campagne = campagneRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Campagne non trouvée avec l'ID : " + id));
        return campagneMapper.toDto(campagne);
    }

    @Override
    public List<CampagneResponseDto> getCampagnesByUtilisateur(Long utilisateurId) {
        return campagneRepository.findByCreateurId(utilisateurId).stream()
            .map(campagneMapper::toDto)
            .collect(Collectors.toList());
    }
}
