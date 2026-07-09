package com.backend.backend.mapper;

import com.backend.backend.dao.entities.AudioCommentaire;
import com.backend.backend.dao.entities.Campagne;
import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.entities.Photo;
import com.backend.backend.dao.entities.StatutFuite;
import com.backend.backend.dto.fuite.FuiteRequestDto;
import com.backend.backend.dto.fuite.FuiteResponseDto;
import org.springframework.stereotype.Component;
import java.util.ArrayList;
import java.util.stream.Collectors;

@Component
public class FuiteMapper {

    public FuiteResponseDto toDto(Fuite fuite) {
        if (fuite == null) {
            return null;
        }
        FuiteResponseDto dto = new FuiteResponseDto();
        dto.setId(fuite.getId());
        dto.setNumeroTag(fuite.getNumeroTag());
        dto.setDateDetection(fuite.getDateDetection());
        dto.setStatut(fuite.getStatut());
        dto.setPressionBar(fuite.getPressionBar());
        dto.setTypeVapeur(fuite.getTypeVapeur());
        dto.setGpsLatitude(fuite.getGpsLatitude());
        dto.setGpsLongitude(fuite.getGpsLongitude());
        dto.setZone(fuite.getZone());
        dto.setDescription(fuite.getDescription());
        dto.setCoutAnnuelEstime(fuite.getCoutAnnuelEstime());
        
        if (fuite.getCampagne() != null) {
            dto.setCampagneId(fuite.getCampagne().getId());
            dto.setCampagneNom(fuite.getCampagne().getNom());
        }
        
        if (fuite.getPhotos() != null) {
            dto.setPhotoIds(
                fuite.getPhotos().stream()
                    .map(Photo::getId)
                    .collect(Collectors.toList())
            );
        } else {
            dto.setPhotoIds(new ArrayList<>());
        }
        
        if (fuite.getAudioCommentaires() != null) {
            dto.setAudioCommentaireIds(
                fuite.getAudioCommentaires().stream()
                    .map(AudioCommentaire::getId)
                    .collect(Collectors.toList())
            );
        } else {
            dto.setAudioCommentaireIds(new ArrayList<>());
        }
        
        return dto;
    }

    public Fuite toEntity(FuiteRequestDto dto) {
        if (dto == null) {
            return null;
        }
        Fuite fuite = new Fuite();
        fuite.setNumeroTag(dto.getNumeroTag());
        fuite.setDateDetection(dto.getDateDetection());
        fuite.setStatut(dto.getStatut() != null ? dto.getStatut() : StatutFuite.A_REPARER);
        fuite.setPressionBar(dto.getPressionBar());
        fuite.setTypeVapeur(dto.getTypeVapeur());
        fuite.setGpsLatitude(dto.getGpsLatitude());
        fuite.setGpsLongitude(dto.getGpsLongitude());
        fuite.setZone(dto.getZone());
        fuite.setDescription(dto.getDescription());
        fuite.setCoutAnnuelEstime(dto.getCoutAnnuelEstime());
        
        if (dto.getCampagneId() != null) {
            Campagne campagne = new Campagne();
            campagne.setId(dto.getCampagneId());
            fuite.setCampagne(campagne);
        }
        
        fuite.setPhotos(new ArrayList<>());
        fuite.setAudioCommentaires(new ArrayList<>());
        
        return fuite;
    }
}
