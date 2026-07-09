package com.backend.backend.service;

import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dao.repositories.UtilisateurRepository;
import com.backend.backend.dto.auth.LoginRequestDto;
import com.backend.backend.dto.auth.RegisterRequestDto;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;
import com.backend.backend.mapper.UtilisateurMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthManager implements AuthService {

    private final UtilisateurRepository utilisateurRepository;
    private final UtilisateurMapper utilisateurMapper;

    @Override
    public UtilisateurResponseDto register(RegisterRequestDto dto) {
        if (utilisateurRepository.existsByEmail(dto.getEmail())) {
            throw new RuntimeException("Un compte avec cet email existe déjà");
        }

        Utilisateur utilisateur = new Utilisateur();
        utilisateur.setNom(dto.getNom());
        utilisateur.setEmail(dto.getEmail());
        utilisateur.setMotDePasse(dto.getMotDePasse());

        utilisateur = utilisateurRepository.save(utilisateur);
        return utilisateurMapper.toDto(utilisateur);
    }

    @Override
    public UtilisateurResponseDto login(LoginRequestDto dto) {
        Utilisateur utilisateur = utilisateurRepository.findByEmail(dto.getEmail())
            .orElseThrow(() -> new RuntimeException("Email ou mot de passe incorrect"));

        if (!utilisateur.getMotDePasse().equals(dto.getMotDePasse())) {
            throw new RuntimeException("Email ou mot de passe incorrect");
        }

        return utilisateurMapper.toDto(utilisateur);
    }
}
