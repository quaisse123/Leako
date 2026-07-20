package com.backend.backend.dto.projet;

public class ProjetRequestDto {
    private String nom;
    private String description;

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
