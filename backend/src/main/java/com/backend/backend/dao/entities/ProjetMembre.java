package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.Date;

@Entity
@Table(name = "projet_membres")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProjetMembre {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "projet_id", nullable = false)
    private Projet projet;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "utilisateur_id", nullable = false)
    private Utilisateur utilisateur;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatutInvitation statut = StatutInvitation.INVITE;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(nullable = false)
    private Date dateInvitation;

    @Temporal(TemporalType.TIMESTAMP)
    private Date dateReponse;
}
