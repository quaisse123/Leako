package com.backend.backend.dto.campagne;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CampagnePatchDto {
    private String nom;
    private String description;
    private String zone;
    private Boolean estCloturee;
    private Long createurId;
}
