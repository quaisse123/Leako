package com.backend.backend.service;

import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dao.repositories.UtilisateurRepository;
import com.backend.backend.dto.auth.LoginRequestDto;
import com.backend.backend.dto.auth.RegisterRequestDto;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;
import com.backend.backend.exception.BusinessException;
import com.backend.backend.mapper.UtilisateurMapper;
import com.backend.backend.service.Jwt.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
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
            throw new BusinessException("Un compte existe déjà avec cet email. Essayez de vous connecter.");
        }

        Utilisateur utilisateur = new Utilisateur();
        utilisateur.setNom(dto.getNom());
        utilisateur.setPrenom(dto.getPrenom());
        utilisateur.setEmail(dto.getEmail());
        utilisateur.setMotDePasse(passwordService.hashPassword(dto.getMotDePasse()));

        utilisateur = utilisateurRepository.save(utilisateur);
        return utilisateurMapper.toDto(utilisateur);
    }

    @Override
    public Map<String, String> login(LoginRequestDto dto) {
        Utilisateur utilisateur = utilisateurRepository.findByEmail(dto.getEmail())
            .orElseThrow(() -> new BusinessException("Email ou mot de passe incorrect", HttpStatus.UNAUTHORIZED));

        if (!passwordService.matches(dto.getMotDePasse(), utilisateur.getMotDePasse())) {
            throw new BusinessException("Email ou mot de passe incorrect", HttpStatus.UNAUTHORIZED);
        }

        // Générer les claims JWT
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", "USER");
        claims.put("userId", utilisateur.getId());
        claims.put("nom", utilisateur.getNom());
        claims.put("prenom", utilisateur.getPrenom());
        claims.put("email", utilisateur.getEmail());

        String accessToken = jwtService.generateToken(claims, jwtAccessDuration, utilisateur.getEmail());
        String refreshToken = jwtService.generateToken(claims, jwtRefreshDuration, utilisateur.getEmail());

        Map<String, String> tokens = new HashMap<>();
        tokens.put("accessToken", accessToken);
        tokens.put("refreshToken", refreshToken);
        tokens.put("userId", String.valueOf(utilisateur.getId()));
        tokens.put("userNom", utilisateur.getNom());
        tokens.put("userPrenom", utilisateur.getPrenom() != null ? utilisateur.getPrenom() : "");
        tokens.put("userEmail", utilisateur.getEmail());

        return tokens;
    }
}
