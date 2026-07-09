package com.backend.backend.dto.audiocommentaire;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AudioCommentaireResponseDto {
    private Long id;
    private String cheminFichier;
    private Integer dureeSecondes;
    private Date dateEnregistrement;
    private String transcription;
    private Long fuiteId;
}
