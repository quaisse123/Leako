package com.backend.backend.web;

import com.backend.backend.dto.campagne.CampagneRequestDto;
import com.backend.backend.dto.campagne.CampagnePatchDto;
import com.backend.backend.dto.campagne.CampagneResponseDto;
import com.backend.backend.service.CampagneService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@CrossOrigin
@RestController
@RequestMapping("/api/campagnes")
@RequiredArgsConstructor
public class CampagneController {

    private final CampagneService service;

    @PostMapping
    public ResponseEntity<CampagneResponseDto> create(@Valid @RequestBody CampagneRequestDto dto) {
        CampagneResponseDto saved = service.createCampagne(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @GetMapping
    public List<CampagneResponseDto> list(@RequestParam(required = false) Long utilisateurId) {
        if (utilisateurId != null) {
            return service.getCampagnesByUtilisateur(utilisateurId);
        }
        return service.getAllCampagnes();
    }

    @GetMapping("/{id}")
    public CampagneResponseDto get(@PathVariable Long id) {
        return service.getCampagneById(id);
    }

    @PutMapping("/{id}")
    public CampagneResponseDto update(@PathVariable Long id, @Valid @RequestBody CampagneRequestDto dto) {
        return service.updateCampagne(id, dto);
    }

    @PatchMapping("/{id}")
    public CampagneResponseDto patch(@PathVariable Long id, @RequestBody CampagnePatchDto dto) {
        return service.patchCampagne(id, dto);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.deleteCampagne(id);
    }
}
