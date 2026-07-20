package com.backend.backend.web;

import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dao.repositories.UtilisateurRepository;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@CrossOrigin
@RestController
@RequestMapping("/api/utilisateurs")
@RequiredArgsConstructor
public class UtilisateurController {

    private final UtilisateurRepository utilisateurRepository;

    @GetMapping
    public List<UtilisateurResponseDto> list() {
        return utilisateurRepository.findAll().stream()
                .map(u -> new UtilisateurResponseDto(u.getId(), u.getNom(), u.getEmail()))
                .collect(Collectors.toList());
    }
}
