package com.backend.backend.mapper;

import com.backend.backend.dao.entities.Projet;
import com.backend.backend.dao.entities.ProjetMembre;
import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dto.projet.ProjetRequestDto;
import com.backend.backend.dto.projet.ProjetResponseDto;
import com.backend.backend.dto.projet.ProjetResponseDto.MembreDto;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class ProjetMapper {

    public ProjetResponseDto toDto(Projet projet) {
        if (projet == null) return null;

        ProjetResponseDto dto = new ProjetResponseDto();
        dto.setId(projet.getId());
        dto.setNom(projet.getNom());
        dto.setDescription(projet.getDescription());
        dto.setDateCreation(projet.getDateCreation());

        if (projet.getCreateur() != null) {
            dto.setCreateurId(projet.getCreateur().getId());
            dto.setCreateurNom(projet.getCreateur().getNom());
        }

        List<MembreDto> membresDto = projet.getMembres() != null
                ? projet.getMembres().stream().map(this::toMembreDto).collect(Collectors.toList())
                : Collections.emptyList();
        dto.setMembres(membresDto);
        dto.setMembresCount(membresDto.size());

        return dto;
    }

    public MembreDto toMembreDto(ProjetMembre pm) {
        if (pm == null) return null;

        MembreDto dto = new MembreDto();
        dto.setId(pm.getId());
        dto.setStatut(pm.getStatut().name());
        dto.setDateInvitation(pm.getDateInvitation());
        dto.setDateReponse(pm.getDateReponse());

        if (pm.getUtilisateur() != null) {
            dto.setUtilisateurId(pm.getUtilisateur().getId());
            dto.setUtilisateurNom(pm.getUtilisateur().getNom());
            dto.setUtilisateurEmail(pm.getUtilisateur().getEmail());
        }

        return dto;
    }

    public Projet toEntity(ProjetRequestDto dto, Utilisateur createur) {
        if (dto == null) return null;

        Projet projet = new Projet();
        projet.setNom(dto.getNom());
        projet.setDescription(dto.getDescription());
        projet.setDateCreation(new Date());
        projet.setCreateur(createur);

        return projet;
    }
}
