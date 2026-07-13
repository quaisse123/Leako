package com.backend.backend.dto.fuite;

import com.backend.backend.dao.entities.StatutFuite;
import com.backend.backend.dao.entities.TypeVapeur;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FuiteRequestDto {

    private String numeroTag;

    @NotNull(message = "La date de détection est obligatoire")
    private Date dateDetection;

    @NotNull(message = "Le statut est obligatoire")
    private StatutFuite statut;

    @Min(value = 0, message = "La pression doit être positive")
    private Double pressionBar;

    @Min(value = 0, message = "Le diamètre doit être positif")
    private Double diametreOrifice;

    private TypeVapeur typeVapeur;

    private Double gpsLatitude;

    private Double gpsLongitude;

    private String zone;

    private String description;

    @Min(value = 0, message = "Le coût annuel estimé doit être positif")
    private Double coutAnnuelEstime;

    @NotNull(message = "L'ID de la campagne est obligatoire")
    private Long campagneId;
}
