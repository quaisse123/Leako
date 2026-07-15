package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.Date;

@Entity
@Table(name = "photos")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Photo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String cheminFichier;

    private String thumbnailUrl;

    @Temporal(TemporalType.DATE)
    private Date datePrise;

    // JSON des tracés manuels (annotations dessin)
    @Lob
    @Column(columnDefinition = "TEXT")
    private String annotationsDessin;

    @ManyToOne
    @JoinColumn(name = "fuite_id", nullable = false)
    private Fuite fuite;
}
