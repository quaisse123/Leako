package com.backend.backend.dto.fuite_message;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FuiteMessageRequestDto {

    @NotNull(message = "L'ID de l'utilisateur est obligatoire")
    private Long utilisateurId;

    private String contenuTexte;

    private String cheminAudio;

    private Integer dureeAudioSecondes;

    @NotNull(message = "L'ID de la fuite est obligatoire")
    private Long fuiteId;
}
