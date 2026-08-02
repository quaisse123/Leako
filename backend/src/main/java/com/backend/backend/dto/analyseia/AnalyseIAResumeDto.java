package com.backend.backend.dto.analyseia;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AnalyseIAResumeDto {
    private String typeFuite;
    private String intensite;
    private double diametreMoyenMm;
    private double confianceMoyenne;
}
