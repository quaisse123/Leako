package com.backend.backend.mapper;

import com.backend.backend.dao.entities.Campagne;
import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dto.campagne.CampagneRequestDto;
import com.backend.backend.dto.campagne.CampagneResponseDto;
import org.springframework.stereotype.Component;
import java.util.ArrayList;
import java.util.Date;
import java.util.stream.Collectors;

@Component
public class CampagneMapper {

    public CampagneResponseDto toDto(Campagne campagne) {
        if (campagne == null) {
            return null;
        }
        CampagneResponseDto dto = new CampagneResponseDto();
        dto.setId(campagne.getId());
        dto.setNom(campagne.getNom());
        dto.setDateCreation(campagne.getDateCreation());
        dto.setDescription(campagne.getDescription());
        dto.setZone(campagne.getZone());
        dto.setEstCloturee(campagne.getEstCloturee());

        if (campagne.getCreateur() != null) {
            dto.setCreateurId(campagne.getCreateur().getId());
            dto.setCreateurNom(campagne.getCreateur().getNom());
        }

        if (campagne.getFuites() != null) {
            dto.setFuiteIds(
                campagne.getFuites().stream()
                    .map(Fuite::getId)
                    .collect(Collectors.toList())
            );
            dto.setNombreFuites(campagne.getFuites().size());
        } else {
            dto.setFuiteIds(new ArrayList<>());
            dto.setNombreFuites(0);
        }

        return dto;
    }

    public Campagne toEntity(CampagneRequestDto dto) {
        if (dto == null) {
            return null;
        }
        Campagne campagne = new Campagne();
        campagne.setNom(dto.getNom());
        campagne.setDescription(dto.getDescription());
        campagne.setZone(dto.getZone());
        campagne.setEstCloturee(dto.getEstCloturee() != null ? dto.getEstCloturee() : false);
        campagne.setDateCreation(new Date());

        if (dto.getCreateurId() != null) {
            Utilisateur createur = new Utilisateur();
            createur.setId(dto.getCreateurId());
            campagne.setCreateur(createur);
        }

        campagne.setFuites(new ArrayList<>());
        return campagne;
    }
}
