package com.backend.backend.dto.parametreglobal;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ParametreGlobalResponseDto {
    private Long id;
    private String devise;
    private Double coutVapeurParTonne;
    private Integer heuresFonctionnementAnnuelles;
    private Double facteurEmissionCO2;
    private String langue;
    private Integer heuresActiviteParJour;
    private Integer joursActiviteParAn;
    private Double coutKwhDiram;
}
