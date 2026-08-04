package com.backend.backend.web;

import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dao.repositories.UtilisateurRepository;
import com.backend.backend.dto.utilisateur.ChangerMotDePasseRequestDto;
import com.backend.backend.dto.utilisateur.UpdateProfilRequestDto;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;
import com.backend.backend.service.UtilisateurService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@CrossOrigin
@RestController
@RequestMapping("/api/utilisateurs")
@RequiredArgsConstructor
public class UtilisateurController {

    private final UtilisateurRepository utilisateurRepository;
    private final UtilisateurService utilisateurService;

    @GetMapping
    public List<UtilisateurResponseDto> list() {
        return utilisateurRepository.findAll().stream()
                .map(u -> new UtilisateurResponseDto(u.getId(), u.getNom(), u.getPrenom(), u.getEmail()))
                .collect(Collectors.toList());
    }

    /** Profil de l'utilisateur connecté (identifié par le JWT). */
    @GetMapping("/me")
    public UtilisateurResponseDto me(Authentication authentication) {
        return utilisateurService.getMe(authentication.getName());
    }

    /** Met à jour nom / prénom / email de l'utilisateur connecté. */
    @PutMapping("/me")
    public ResponseEntity<?> updateMe(@Valid @RequestBody UpdateProfilRequestDto dto,
                                      Authentication authentication) {
        try {
            UtilisateurResponseDto updated = utilisateurService.updateProfil(authentication.getName(), dto);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /** Change le mot de passe de l'utilisateur connecté. */
    @PutMapping("/me/mot-de-passe")
    public ResponseEntity<?> changerMotDePasse(@Valid @RequestBody ChangerMotDePasseRequestDto dto,
                                               Authentication authentication) {
        try {
            utilisateurService.changerMotDePasse(authentication.getName(), dto);
            return ResponseEntity.ok(Map.of("message", "Mot de passe modifié avec succès"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
