package com.backend.backend.dto.campagne;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CampagneResponseDto {
    private Long id;
    private String nom;
    private Date dateCreation;
    private String description;
    private String zone;
    private Boolean estCloturee;
    private Long createurId;
    private String createurNom;
    private Long projetId;
    private List<Long> fuiteIds;
    private int nombreFuites;
}
