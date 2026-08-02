package com.backend.backend.dto.analyseia;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AnalyseIAMediaDto {
    private String fichier;
    private boolean fuiteVisible;
    private String typeFuite;
    private String intensite;
    private double diametreEstimeMm;
    private double confiance;
    private String observation;
}
