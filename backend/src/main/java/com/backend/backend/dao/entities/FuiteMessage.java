package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.Date;

@Entity
@Table(name = "fuite_messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FuiteMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long utilisateurId;

    @Lob
    @Column(columnDefinition = "TEXT")
    private String contenuTexte;

    private String cheminAudio;

    private Integer dureeAudioSecondes;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(nullable = false)
    private Date dateEnvoi;

    @ManyToOne
    @JoinColumn(name = "fuite_id", nullable = false)
    private Fuite fuite;
}
