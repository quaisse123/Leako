package com.backend.backend.dto.projet;

import java.util.Date;
import java.util.List;

public class ProjetResponseDto {
    private Long id;
    private String nom;
    private String description;
    private Date dateCreation;
    private Long createurId;
    private String createurNom;
    private int membresCount;
    private List<MembreDto> membres;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Date getDateCreation() { return dateCreation; }
    public void setDateCreation(Date dateCreation) { this.dateCreation = dateCreation; }

    public Long getCreateurId() { return createurId; }
    public void setCreateurId(Long createurId) { this.createurId = createurId; }

    public String getCreateurNom() { return createurNom; }
    public void setCreateurNom(String createurNom) { this.createurNom = createurNom; }

    public int getMembresCount() { return membresCount; }
    public void setMembresCount(int membresCount) { this.membresCount = membresCount; }

    public List<MembreDto> getMembres() { return membres; }
    public void setMembres(List<MembreDto> membres) { this.membres = membres; }

    public static class MembreDto {
        private Long id;
        private Long utilisateurId;
        private String utilisateurNom;
        private String utilisateurEmail;
        private String statut;
        private Date dateInvitation;
        private Date dateReponse;

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }

        public Long getUtilisateurId() { return utilisateurId; }
        public void setUtilisateurId(Long utilisateurId) { this.utilisateurId = utilisateurId; }

        public String getUtilisateurNom() { return utilisateurNom; }
        public void setUtilisateurNom(String utilisateurNom) { this.utilisateurNom = utilisateurNom; }

        public String getUtilisateurEmail() { return utilisateurEmail; }
        public void setUtilisateurEmail(String utilisateurEmail) { this.utilisateurEmail = utilisateurEmail; }

        public String getStatut() { return statut; }
        public void setStatut(String statut) { this.statut = statut; }

        public Date getDateInvitation() { return dateInvitation; }
        public void setDateInvitation(Date dateInvitation) { this.dateInvitation = dateInvitation; }

        public Date getDateReponse() { return dateReponse; }
        public void setDateReponse(Date dateReponse) { this.dateReponse = dateReponse; }
    }
}
