package com.backend.backend.service;

import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dao.repositories.UtilisateurRepository;
import com.backend.backend.dto.utilisateur.ChangerMotDePasseRequestDto;
import com.backend.backend.dto.utilisateur.UpdateProfilRequestDto;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;
import com.backend.backend.mapper.UtilisateurMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UtilisateurService {

    private final UtilisateurRepository utilisateurRepository;
    private final UtilisateurMapper utilisateurMapper;
    private final PasswordService passwordService;

    /** Retourne le profil de l'utilisateur courant (identifié par son email JWT). */
    public UtilisateurResponseDto getMe(String email) {
        return utilisateurMapper.toDto(requireUser(email));
    }

    /** Met à jour nom / prénom / email de l'utilisateur courant. */
    @Transactional
    public UtilisateurResponseDto updateProfil(String email, UpdateProfilRequestDto dto) {
        Utilisateur utilisateur = requireUser(email);

        // Unicité de l'email : vérifie qu'aucun AUTRE utilisateur ne possède ce nouvel email.
        if (!utilisateur.getEmail().equalsIgnoreCase(dto.getEmail())
                && utilisateurRepository.existsByEmail(dto.getEmail())) {
            throw new RuntimeException("Un compte avec cet email existe déjà");
        }

        utilisateur.setNom(dto.getNom());
        utilisateur.setPrenom(dto.getPrenom());
        utilisateur.setEmail(dto.getEmail());
        utilisateur = utilisateurRepository.save(utilisateur);
        return utilisateurMapper.toDto(utilisateur);
    }

    /** Change le mot de passe après vérification de l'ancien. */
    @Transactional
    public void changerMotDePasse(String email, ChangerMotDePasseRequestDto dto) {
        Utilisateur utilisateur = requireUser(email);

        if (!passwordService.matches(dto.getMotDePasseActuel(), utilisateur.getMotDePasse())) {
            throw new RuntimeException("Le mot de passe actuel est incorrect");
        }

        utilisateur.setMotDePasse(passwordService.hashPassword(dto.getNouveauMotDePasse()));
        utilisateurRepository.save(utilisateur);
    }

    private Utilisateur requireUser(String email) {
        return utilisateurRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Utilisateur introuvable"));
    }
}
