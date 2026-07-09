package com.backend.backend.web;

import com.backend.backend.dto.fuite.FuiteRequestDto;
import com.backend.backend.dto.fuite.FuiteResponseDto;
import com.backend.backend.service.FuiteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@CrossOrigin
@RestController
@RequestMapping("/api/fuites")
@RequiredArgsConstructor
public class FuiteController {

    private final FuiteService service;

    @PostMapping
    public ResponseEntity<FuiteResponseDto> create(@Valid @RequestBody FuiteRequestDto dto) {
        FuiteResponseDto saved = service.createFuite(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @GetMapping
    public List<FuiteResponseDto> list(
            @RequestParam(required = false) Long campagneId,
            @RequestParam(required = false) Long utilisateurId) {
        if (campagneId != null) {
            return service.getFuitesByCampagne(campagneId);
        }
        if (utilisateurId != null) {
            return service.getFuitesByUtilisateur(utilisateurId);
        }
        return service.getAllFuites();
    }

    @GetMapping("/{id}")
    public FuiteResponseDto get(@PathVariable Long id) {
        return service.getFuiteById(id);
    }

    @PutMapping("/{id}")
    public FuiteResponseDto update(@PathVariable Long id, @Valid @RequestBody FuiteRequestDto dto) {
        return service.updateFuite(id, dto);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.deleteFuite(id);
    }
}
