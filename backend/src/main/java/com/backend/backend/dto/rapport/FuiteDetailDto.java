package com.backend.backend.dto.rapport;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FuiteDetailDto {
    private String numeroTag;
    private String localisation;
    private String dateDetection;
}
