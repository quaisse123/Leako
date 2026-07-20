package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.FuiteMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FuiteMessageRepository extends JpaRepository<FuiteMessage, Long> {

    List<FuiteMessage> findByFuiteIdOrderByDateEnvoiAsc(Long fuiteId);
}
