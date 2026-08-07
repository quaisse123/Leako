package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
@Entity
@Table(name = "utilisateurs")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Utilisateur {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nom;

    @Column
    private String prenom;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String motDePasse;

    /**
     * Retourne le nom complet "prénom nom", ou simplement le nom
     * si le prénom est absent.
     */
    public String getNomComplet() {
        if (prenom != null && !prenom.isBlank()) {
            return prenom + " " + nom;
        }
        return nom;
    }
}
