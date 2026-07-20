package com.backend.backend.dto.fuite_message;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FuiteMessageResponseDto {
    private Long id;
    private Long utilisateurId;
    private String nomUtilisateur;
    private String contenuTexte;
    private String cheminAudio;
    private Integer dureeAudioSecondes;
    private Date dateEnvoi;
    private Long fuiteId;
}
