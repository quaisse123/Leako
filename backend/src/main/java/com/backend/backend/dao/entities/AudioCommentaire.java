package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.Date;

@Entity
@Table(name = "audio_commentaires")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AudioCommentaire {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String cheminFichier;

    private Integer dureeSecondes;

    @Temporal(TemporalType.TIMESTAMP)
    private Date dateEnregistrement;

    // Transcription via Whisper (null si pas encore transcrit)
    @Lob
    @Column(columnDefinition = "TEXT")
    private String transcription;

    @ManyToOne
    @JoinColumn(name = "fuite_id", nullable = false)
    private Fuite fuite;
}
