package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.Date;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "campagnes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Campagne {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nom;

    private String description;

    private String zone;

    @Column(nullable = false)
    private Boolean estCloturee = false;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(nullable = false)
    private Date dateCreation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "utilisateur_id", nullable = false)
    private Utilisateur createur;

    @OneToMany(mappedBy = "campagne", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Fuite> fuites = new ArrayList<>();
}
