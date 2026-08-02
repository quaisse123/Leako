package com.backend.backend.dto.analyseia;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AnalyseIAReponseDto {
    private boolean success;
    private List<AnalyseIAMediaDto> resultats;
    private AnalyseIAResumeDto resume;
    private String synthese;
    private List<String> warnings;
}
