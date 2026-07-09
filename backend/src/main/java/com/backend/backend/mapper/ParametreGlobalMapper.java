package com.backend.backend.mapper;

import com.backend.backend.dao.entities.ParametreGlobal;
import com.backend.backend.dto.parametreglobal.ParametreGlobalRequestDto;
import com.backend.backend.dto.parametreglobal.ParametreGlobalResponseDto;
import org.springframework.stereotype.Component;

@Component
public class ParametreGlobalMapper {

    public ParametreGlobalResponseDto toDto(ParametreGlobal param) {
        if (param == null) {
            return null;
        }
        ParametreGlobalResponseDto dto = new ParametreGlobalResponseDto();
        dto.setId(param.getId());
        dto.setDevise(param.getDevise());
        dto.setCoutVapeurParTonne(param.getCoutVapeurParTonne());
        dto.setHeuresFonctionnementAnnuelles(param.getHeuresFonctionnementAnnuelles());
        dto.setFacteurEmissionCO2(param.getFacteurEmissionCO2());
        dto.setLangue(param.getLangue());
        dto.setHeuresActiviteParJour(param.getHeuresActiviteParJour());
        dto.setJoursActiviteParAn(param.getJoursActiviteParAn());
        dto.setCoutKwhDiram(param.getCoutKwhDiram());
        return dto;
    }

    public ParametreGlobal toEntity(ParametreGlobalRequestDto dto) {
        if (dto == null) {
            return null;
        }
        ParametreGlobal param = new ParametreGlobal();
        param.setDevise(dto.getDevise() != null ? dto.getDevise() : "MAD");
        param.setCoutVapeurParTonne(dto.getCoutVapeurParTonne());
        param.setHeuresFonctionnementAnnuelles(dto.getHeuresFonctionnementAnnuelles());
        param.setFacteurEmissionCO2(dto.getFacteurEmissionCO2());
        param.setLangue(dto.getLangue() != null ? dto.getLangue() : "fr");
        param.setHeuresActiviteParJour(dto.getHeuresActiviteParJour() != null ? dto.getHeuresActiviteParJour() : 24);
        param.setJoursActiviteParAn(dto.getJoursActiviteParAn() != null ? dto.getJoursActiviteParAn() : 365);
        param.setCoutKwhDiram(dto.getCoutKwhDiram() != null ? dto.getCoutKwhDiram() : 0.0);
        return param;
    }
}
