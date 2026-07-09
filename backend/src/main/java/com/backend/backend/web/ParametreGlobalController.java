package com.backend.backend.web;

import com.backend.backend.dto.parametreglobal.ParametreGlobalRequestDto;
import com.backend.backend.dto.parametreglobal.ParametreGlobalResponseDto;
import com.backend.backend.service.ParametreGlobalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@CrossOrigin
@RestController
@RequestMapping("/api/parametres")
@RequiredArgsConstructor
public class ParametreGlobalController {

    private final ParametreGlobalService service;

    @GetMapping
    public ParametreGlobalResponseDto get() {
        return service.getParametres();
    }

    @PutMapping
    public ParametreGlobalResponseDto update(@Valid @RequestBody ParametreGlobalRequestDto dto) {
        return service.updateParametres(dto);
    }
}
