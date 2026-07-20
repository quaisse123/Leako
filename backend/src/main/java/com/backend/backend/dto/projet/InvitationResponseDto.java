package com.backend.backend.dto.projet;

import java.util.Date;

public class InvitationResponseDto {
    private Long id;
    private Long projetId;
    private String projetNom;
    private Long createurId;
    private String createurNom;
    private Long utilisateurId;
    private String utilisateurNom;
    private String statut;
    private Date dateInvitation;
    private Date dateReponse;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getProjetId() { return projetId; }
    public void setProjetId(Long projetId) { this.projetId = projetId; }

    public String getProjetNom() { return projetNom; }
    public void setProjetNom(String projetNom) { this.projetNom = projetNom; }

    public Long getCreateurId() { return createurId; }
    public void setCreateurId(Long createurId) { this.createurId = createurId; }

    public String getCreateurNom() { return createurNom; }
    public void setCreateurNom(String createurNom) { this.createurNom = createurNom; }

    public Long getUtilisateurId() { return utilisateurId; }
    public void setUtilisateurId(Long utilisateurId) { this.utilisateurId = utilisateurId; }

    public String getUtilisateurNom() { return utilisateurNom; }
    public void setUtilisateurNom(String utilisateurNom) { this.utilisateurNom = utilisateurNom; }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }

    public Date getDateInvitation() { return dateInvitation; }
    public void setDateInvitation(Date dateInvitation) { this.dateInvitation = dateInvitation; }

    public Date getDateReponse() { return dateReponse; }
    public void setDateReponse(Date dateReponse) { this.dateReponse = dateReponse; }
}
