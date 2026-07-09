package com.backend.backend.mapper;

import com.backend.backend.dao.entities.AudioCommentaire;
import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dto.audiocommentaire.AudioCommentaireRequestDto;
import com.backend.backend.dto.audiocommentaire.AudioCommentaireResponseDto;
import org.springframework.stereotype.Component;

@Component
public class AudioCommentaireMapper {

    public AudioCommentaireResponseDto toDto(AudioCommentaire audio) {
        if (audio == null) {
            return null;
        }
        AudioCommentaireResponseDto dto = new AudioCommentaireResponseDto();
        dto.setId(audio.getId());
        dto.setCheminFichier(audio.getCheminFichier());
        dto.setDureeSecondes(audio.getDureeSecondes());
        dto.setDateEnregistrement(audio.getDateEnregistrement());
        dto.setTranscription(audio.getTranscription());
        
        if (audio.getFuite() != null) {
            dto.setFuiteId(audio.getFuite().getId());
        }
        
        return dto;
    }

    public AudioCommentaire toEntity(AudioCommentaireRequestDto dto) {
        if (dto == null) {
            return null;
        }
        AudioCommentaire audio = new AudioCommentaire();
        audio.setCheminFichier(dto.getCheminFichier());
        audio.setDureeSecondes(dto.getDureeSecondes());
        audio.setDateEnregistrement(dto.getDateEnregistrement());
        audio.setTranscription(dto.getTranscription());
        
        if (dto.getFuiteId() != null) {
            Fuite fuite = new Fuite();
            fuite.setId(dto.getFuiteId());
            audio.setFuite(fuite);
        }
        
        return audio;
    }
}
