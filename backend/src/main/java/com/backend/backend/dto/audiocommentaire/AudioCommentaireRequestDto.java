package com.backend.backend.dto.audiocommentaire;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AudioCommentaireRequestDto {

    @NotBlank(message = "Le chemin du fichier est obligatoire")
    private String cheminFichier;

    private Integer dureeSecondes;

    private Date dateEnregistrement;

    private String transcription;

    @NotNull(message = "L'ID de la fuite est obligatoire")
    private Long fuiteId;
}
