package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Entity
@Table(name = "parametres_globaux")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ParametreGlobal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String devise = "MAD";

    private Double coutVapeurParTonne;

    private Integer heuresFonctionnementAnnuelles;

    private Double facteurEmissionCO2;

    @Column(nullable = false)
    private String langue = "fr";

    @Column(nullable = false)
    private Integer heuresActiviteParJour = 24;

    @Column(nullable = false)
    private Integer joursActiviteParAn = 365;

    @Column(nullable = false)
    private Double coutKwhDiram = 0.0;
}
