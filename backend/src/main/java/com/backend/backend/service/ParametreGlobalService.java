package com.backend.backend.service;

import com.backend.backend.dto.parametreglobal.ParametreGlobalRequestDto;
import com.backend.backend.dto.parametreglobal.ParametreGlobalResponseDto;

public interface ParametreGlobalService {

    ParametreGlobalResponseDto getParametres();

    ParametreGlobalResponseDto updateParametres(ParametreGlobalRequestDto dto);
}
