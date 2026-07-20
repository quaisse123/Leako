package com.backend.backend.dto.rapport;

import com.backend.backend.dao.entities.StatutFuite;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FuiteResumeDto {
    private Long id;
    private String numeroTag;
    private String campagneNom;
    private Double coutAnnuelEstime;
    private StatutFuite statut;
}
