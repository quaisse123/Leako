package com.backend.backend.mapper;

import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.entities.FuiteMessage;
import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dto.fuite_message.FuiteMessageRequestDto;
import com.backend.backend.dto.fuite_message.FuiteMessageResponseDto;
import com.backend.backend.dao.repositories.UtilisateurRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class FuiteMessageMapper {

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    public FuiteMessageResponseDto toDto(FuiteMessage message) {
        if (message == null) {
            return null;
        }
        FuiteMessageResponseDto dto = new FuiteMessageResponseDto();
        dto.setId(message.getId());
        dto.setUtilisateurId(message.getUtilisateurId());
        dto.setContenuTexte(message.getContenuTexte());
        dto.setCheminAudio(message.getCheminAudio());
        dto.setDureeAudioSecondes(message.getDureeAudioSecondes());
        dto.setDateEnvoi(message.getDateEnvoi());

        // Récupérer le nom de l'utilisateur
        utilisateurRepository.findById(message.getUtilisateurId()).ifPresent(u ->
            dto.setNomUtilisateur(u.getNom())
        );

        if (message.getFuite() != null) {
            dto.setFuiteId(message.getFuite().getId());
        }

        return dto;
    }

    public FuiteMessage toEntity(FuiteMessageRequestDto dto) {
        if (dto == null) {
            return null;
        }
        FuiteMessage message = new FuiteMessage();
        message.setUtilisateurId(dto.getUtilisateurId());
        message.setContenuTexte(dto.getContenuTexte());
        message.setCheminAudio(dto.getCheminAudio());
        message.setDureeAudioSecondes(dto.getDureeAudioSecondes());

        if (dto.getFuiteId() != null) {
            Fuite fuite = new Fuite();
            fuite.setId(dto.getFuiteId());
            message.setFuite(fuite);
        }

        return message;
    }
}
