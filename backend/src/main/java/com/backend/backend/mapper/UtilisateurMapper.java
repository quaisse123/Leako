package com.backend.backend.mapper;

import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dto.utilisateur.UtilisateurRequestDto;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;
import org.springframework.stereotype.Component;

@Component
public class UtilisateurMapper {

    public UtilisateurResponseDto toDto(Utilisateur utilisateur) {
        if (utilisateur == null) {
            return null;
        }
        UtilisateurResponseDto dto = new UtilisateurResponseDto();
        dto.setId(utilisateur.getId());
        dto.setNom(utilisateur.getNom());
        dto.setEmail(utilisateur.getEmail());
        return dto;
    }

    public Utilisateur toEntity(UtilisateurRequestDto dto) {
        if (dto == null) {
            return null;
        }
        Utilisateur utilisateur = new Utilisateur();
        utilisateur.setNom(dto.getNom());
        utilisateur.setEmail(dto.getEmail());
        utilisateur.setMotDePasse(dto.getMotDePasse());
        return utilisateur;
    }
}
