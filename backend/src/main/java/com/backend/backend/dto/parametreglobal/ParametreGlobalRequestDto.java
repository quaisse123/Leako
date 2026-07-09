package com.backend.backend.dto.parametreglobal;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ParametreGlobalRequestDto {

    @NotBlank(message = "La devise est obligatoire")
    private String devise;

    @NotNull(message = "Le coût de la vapeur par tonne est obligatoire")
    @Min(value = 0, message = "Le coût de la vapeur doit être positif")
    private Double coutVapeurParTonne;

    @NotNull(message = "Les heures de fonctionnement annuelles sont obligatoires")
    @Min(value = 0, message = "Les heures de fonctionnement doivent être positives")
    private Integer heuresFonctionnementAnnuelles;

    @NotNull(message = "Le facteur d'émission CO2 est obligatoire")
    @Min(value = 0, message = "Le facteur d'émission CO2 doit être positif")
    private Double facteurEmissionCO2;

    @NotBlank(message = "La langue est obligatoire")
    private String langue;

    @NotNull(message = "Les heures d'activité par jour sont obligatoires")
    @Min(value = 1, message = "Au moins 1 heure par jour")
    private Integer heuresActiviteParJour;

    @NotNull(message = "Les jours d'activité par an sont obligatoires")
    @Min(value = 1, message = "Au moins 1 jour par an")
    private Integer joursActiviteParAn;

    @NotNull(message = "Le coût kWh/Diram est obligatoire")
    @Min(value = 0, message = "Le coût kWh/Diram doit être positif")
    private Double coutKwhDiram;
}
