package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.Projet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface ProjetRepository extends JpaRepository<Projet, Long> {

    // Projets créés par l'utilisateur
    List<Projet> findByCreateurId(Long createurId);

    // Projets où l'utilisateur est membre (accepté)
    @Query("SELECT pm.projet FROM ProjetMembre pm WHERE pm.utilisateur.id = :utilisateurId AND pm.statut = 'ACCEPTE'")
    List<Projet> findProjetsByMembreId(@Param("utilisateurId") Long utilisateurId);
}
