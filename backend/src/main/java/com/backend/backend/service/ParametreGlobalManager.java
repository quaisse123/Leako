package com.backend.backend.service;

import com.backend.backend.dao.entities.ParametreGlobal;
import com.backend.backend.dao.repositories.ParametreGlobalRepository;
import com.backend.backend.dto.parametreglobal.ParametreGlobalRequestDto;
import com.backend.backend.dto.parametreglobal.ParametreGlobalResponseDto;
import com.backend.backend.mapper.ParametreGlobalMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ParametreGlobalManager implements ParametreGlobalService {

    private final ParametreGlobalRepository parametreGlobalRepository;
    private final ParametreGlobalMapper parametreGlobalMapper;

    @Override
    public ParametreGlobalResponseDto getParametres() {
        ParametreGlobal params = parametreGlobalRepository.findById(1L)
            .orElseGet(() -> {
                ParametreGlobal defaults = new ParametreGlobal();
                defaults.setId(1L);
                return parametreGlobalRepository.save(defaults);
            });
        return parametreGlobalMapper.toDto(params);
    }

    @Override
    public ParametreGlobalResponseDto updateParametres(ParametreGlobalRequestDto dto) {
        ParametreGlobal params = parametreGlobalRepository.findById(1L)
            .orElseGet(() -> {
                ParametreGlobal p = new ParametreGlobal();
                p.setId(1L);
                return p;
            });

        params.setDevise(dto.getDevise() != null ? dto.getDevise() : "MAD");
        params.setCoutVapeurParTonne(dto.getCoutVapeurParTonne());
        params.setHeuresFonctionnementAnnuelles(dto.getHeuresFonctionnementAnnuelles());
        params.setFacteurEmissionCO2(dto.getFacteurEmissionCO2());
        params.setLangue(dto.getLangue() != null ? dto.getLangue() : "fr");
        params.setHeuresActiviteParJour(dto.getHeuresActiviteParJour() != null ? dto.getHeuresActiviteParJour() : 24);
        params.setJoursActiviteParAn(dto.getJoursActiviteParAn() != null ? dto.getJoursActiviteParAn() : 365);
        params.setCoutKwhDiram(dto.getCoutKwhDiram() != null ? dto.getCoutKwhDiram() : 0.0);

        params = parametreGlobalRepository.save(params);
        return parametreGlobalMapper.toDto(params);
    }
}
