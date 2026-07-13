package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.Date;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "fuites")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Fuite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String numeroTag;

    @Temporal(TemporalType.DATE)
    @Column(nullable = false)
    private Date dateDetection;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatutFuite statut = StatutFuite.A_REPARER;

    private Double pressionBar;

    private Double diametreOrifice;

    @Enumerated(EnumType.STRING)
    private TypeVapeur typeVapeur;

    private Double gpsLatitude;

    private Double gpsLongitude;

    private String zone;

    @Lob
    @Column(columnDefinition = "TEXT")
    private String description;

    private Double coutAnnuelEstime;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campagne_id", nullable = false)
    private Campagne campagne;

    @OneToMany(mappedBy = "fuite", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Photo> photos = new ArrayList<>();

    @OneToMany(mappedBy = "fuite", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AudioCommentaire> audioCommentaires = new ArrayList<>();
}
