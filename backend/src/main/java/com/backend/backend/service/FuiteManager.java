package com.backend.backend.service;

import com.backend.backend.dao.entities.Campagne;
import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.repositories.CampagneRepository;
import com.backend.backend.dao.repositories.FuiteRepository;
import com.backend.backend.dto.fuite.FuiteRequestDto;
import com.backend.backend.dto.fuite.FuiteResponseDto;
import com.backend.backend.mapper.FuiteMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FuiteManager implements FuiteService {

    private final FuiteRepository fuiteRepository;
    private final CampagneRepository campagneRepository;
    private final FuiteMapper fuiteMapper;

    @Override
    public FuiteResponseDto createFuite(FuiteRequestDto dto) {
        Fuite fuite = fuiteMapper.toEntity(dto);

        if (dto.getCampagneId() != null) {
            Campagne campagne = campagneRepository.findById(dto.getCampagneId())
                .orElseThrow(() -> new RuntimeException("Campagne non trouvée avec l'ID : " + dto.getCampagneId()));
            fuite.setCampagne(campagne);
        }

        fuite = fuiteRepository.save(fuite);
        return fuiteMapper.toDto(fuite);
    }

    @Override
    public FuiteResponseDto updateFuite(Long id, FuiteRequestDto dto) {
        Fuite fuite = fuiteRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Fuite non trouvée avec l'ID : " + id));

        fuite.setNumeroTag(dto.getNumeroTag());
        fuite.setDateDetection(dto.getDateDetection());
        fuite.setStatut(dto.getStatut());
        fuite.setPressionBar(dto.getPressionBar());
        fuite.setTypeVapeur(dto.getTypeVapeur());
        fuite.setGpsLatitude(dto.getGpsLatitude());
        fuite.setGpsLongitude(dto.getGpsLongitude());
        fuite.setZone(dto.getZone());
        fuite.setDescription(dto.getDescription());
        fuite.setCoutAnnuelEstime(dto.getCoutAnnuelEstime());

        fuite = fuiteRepository.save(fuite);
        return fuiteMapper.toDto(fuite);
    }

    @Override
    public void deleteFuite(Long id) {
        if (!fuiteRepository.existsById(id)) {
            throw new RuntimeException("Fuite non trouvée avec l'ID : " + id);
        }
        fuiteRepository.deleteById(id);
    }

    @Override
    public List<FuiteResponseDto> getAllFuites() {
        return fuiteRepository.findAll().stream()
            .map(fuiteMapper::toDto)
            .collect(Collectors.toList());
    }

    @Override
    public FuiteResponseDto getFuiteById(Long id) {
        Fuite fuite = fuiteRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Fuite non trouvée avec l'ID : " + id));
        return fuiteMapper.toDto(fuite);
    }

    @Override
    public List<FuiteResponseDto> getFuitesByCampagne(Long campagneId) {
        return fuiteRepository.findByCampagneId(campagneId).stream()
            .map(fuiteMapper::toDto)
            .collect(Collectors.toList());
    }

    @Override
    public List<FuiteResponseDto> getFuitesByUtilisateur(Long utilisateurId) {
        return fuiteRepository.findByCreateurId(utilisateurId).stream()
            .map(fuiteMapper::toDto)
            .collect(Collectors.toList());
    }
}
