package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.Campagne;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CampagneRepository extends JpaRepository<Campagne, Long> {

    List<Campagne> findByCreateurId(Long createurId);

    List<Campagne> findByProjetId(Long projetId);
}
