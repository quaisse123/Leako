package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.Fuite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface FuiteRepository extends JpaRepository<Fuite, Long> {

    // Toutes les fuites d'une campagne
    List<Fuite> findByCampagneId(Long campagneId);

    // Toutes les fuites d'un utilisateur (via le createur de la campagne)
    @Query("SELECT f FROM Fuite f JOIN f.campagne c WHERE c.createur.id = :utilisateurId")
    List<Fuite> findByCreateurId(@Param("utilisateurId") Long utilisateurId);

    // Toutes les fuites d'un projet (via la campagne)
    @Query("SELECT f FROM Fuite f JOIN f.campagne c WHERE c.projet.id = :projetId")
    List<Fuite> findByProjetId(@Param("projetId") Long projetId);
}
