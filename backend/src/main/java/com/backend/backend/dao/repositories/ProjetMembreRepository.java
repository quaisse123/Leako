package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.ProjetMembre;
import com.backend.backend.dao.entities.StatutInvitation;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface ProjetMembreRepository extends JpaRepository<ProjetMembre, Long> {

    // Invitations pour un utilisateur (en attente)
    List<ProjetMembre> findByUtilisateurIdAndStatut(Long utilisateurId, StatutInvitation statut);

    // Toutes les invitations d'un utilisateur
    List<ProjetMembre> findByUtilisateurId(Long utilisateurId);

    // Vérifier si un utilisateur est déjà membre/invité
    Optional<ProjetMembre> findByProjetIdAndUtilisateurId(Long projetId, Long utilisateurId);

    // Membres d'un projet
    List<ProjetMembre> findByProjetId(Long projetId);
}
