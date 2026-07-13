package com.backend.backend.service;

import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dao.repositories.UtilisateurRepository;
import com.backend.backend.dto.auth.LoginRequestDto;
import com.backend.backend.dto.auth.RegisterRequestDto;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;
import com.backend.backend.mapper.UtilisateurMapper;
import com.backend.backend.service.Jwt.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthManager implements AuthService {

    private final UtilisateurRepository utilisateurRepository;
    private final UtilisateurMapper utilisateurMapper;
    private final PasswordService passwordService;
    private final JwtService jwtService;

    @Value("${jwt.access.duration}")
    private long jwtAccessDuration;

    @Value("${jwt.refresh.duration}")
    private long jwtRefreshDuration;

    @Override
    public UtilisateurResponseDto register(RegisterRequestDto dto) {
        if (utilisateurRepository.existsByEmail(dto.getEmail())) {
            throw new RuntimeException("Un compte avec cet email existe déjà");
        }

        Utilisateur utilisateur = new Utilisateur();
        utilisateur.setNom(dto.getNom());
        utilisateur.setEmail(dto.getEmail());
        utilisateur.setMotDePasse(passwordService.hashPassword(dto.getMotDePasse()));

        utilisateur = utilisateurRepository.save(utilisateur);
        return utilisateurMapper.toDto(utilisateur);
    }

    @Override
    public Map<String, String> login(LoginRequestDto dto) {
        Utilisateur utilisateur = utilisateurRepository.findByEmail(dto.getEmail())
            .orElseThrow(() -> new RuntimeException("Email ou mot de passe incorrect"));

        if (!passwordService.matches(dto.getMotDePasse(), utilisateur.getMotDePasse())) {
            throw new RuntimeException("Email ou mot de passe incorrect");
        }

        // Générer les claims JWT
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", "USER");
        claims.put("userId", utilisateur.getId());
        claims.put("nom", utilisateur.getNom());
        claims.put("email", utilisateur.getEmail());

        String accessToken = jwtService.generateToken(claims, jwtAccessDuration, utilisateur.getEmail());
        String refreshToken = jwtService.generateToken(claims, jwtRefreshDuration, utilisateur.getEmail());

        Map<String, String> tokens = new HashMap<>();
        tokens.put("accessToken", accessToken);
        tokens.put("refreshToken", refreshToken);
        tokens.put("userId", String.valueOf(utilisateur.getId()));
        tokens.put("userNom", utilisateur.getNom());
        tokens.put("userEmail", utilisateur.getEmail());

        return tokens;
    }
}
