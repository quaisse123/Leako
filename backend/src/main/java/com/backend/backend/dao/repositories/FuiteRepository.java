package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.Fuite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface FuiteRepository extends JpaRepository<Fuite, Long> {

    // Toutes les fuites d'une campagne
    List<Fuite> findByCampagneId(Long campagneId);

    // Toutes les fuites d'un utilisateur (via le createur de la campagne)
    @Query("SELECT f FROM Fuite f JOIN f.campagne c WHERE c.createur.id = :utilisateurId")
    List<Fuite> findByCreateurId(@Param("utilisateurId") Long utilisateurId);

    // Toutes les fuites d'un projet (via la campagne)
    @Query("SELECT f FROM Fuite f JOIN f.campagne c WHERE c.projet.id = :projetId")
    List<Fuite> findByProjetId(@Param("projetId") Long projetId);

    // Compter les fuites dont le tag commence par un préfixe
    @Query("SELECT COUNT(f) FROM Fuite f WHERE f.numeroTag LIKE :prefix%")
    long countByNumeroTagStartingWith(@Param("prefix") String prefix);

    // Compter les fuites d'une campagne dont le tag commence par un préfixe
    @Query("SELECT COUNT(f) FROM Fuite f WHERE f.campagne.id = :campagneId AND f.numeroTag LIKE :prefix%")
    long countByCampagneIdAndNumeroTagStartingWith(@Param("campagneId") Long campagneId, @Param("prefix") String prefix);

    // Vérifier si un tag existe déjà
    boolean existsByNumeroTag(String numeroTag);
}
