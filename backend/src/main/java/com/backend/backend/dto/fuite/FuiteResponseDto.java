package com.backend.backend.dto.fuite;

import com.backend.backend.dao.entities.StatutFuite;
import com.backend.backend.dao.entities.TypeVapeur;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FuiteResponseDto {
    private Long id;
    private String numeroTag;
    private Date dateDetection;
    private StatutFuite statut;
    private Double pressionBar;
    private Double diametreOrifice;
    private TypeVapeur typeVapeur;
    private Double gpsLatitude;
    private Double gpsLongitude;
    private String zone;
    private String description;
    private Double coutAnnuelEstime;
    private Long campagneId;
    private String campagneNom;
    private List<Long> photoIds;
    private List<Long> audioCommentaireIds;
}
