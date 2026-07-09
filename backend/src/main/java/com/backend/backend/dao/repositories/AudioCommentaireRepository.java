package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.AudioCommentaire;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface AudioCommentaireRepository extends JpaRepository<AudioCommentaire, Long> {

    List<AudioCommentaire> findByFuiteId(Long fuiteId);
}
