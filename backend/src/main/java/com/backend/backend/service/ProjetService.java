package com.backend.backend.service;

import com.backend.backend.dto.projet.InvitationRequestDto;
import com.backend.backend.dto.projet.InvitationResponseDto;
import com.backend.backend.dto.projet.ProjetRequestDto;
import com.backend.backend.dto.projet.ProjetResponseDto;

import java.util.List;

public interface ProjetService {

    ProjetResponseDto createProjet(ProjetRequestDto dto, Long createurId);

    ProjetResponseDto getProjetById(Long projetId, Long utilisateurId);

    List<ProjetResponseDto> getMesProjets(Long utilisateurId);

    ProjetResponseDto updateProjet(Long projetId, ProjetRequestDto dto, Long utilisateurId);

    void deleteProjet(Long projetId, Long utilisateurId);

    // Invitations
    InvitationResponseDto inviterMembre(Long projetId, InvitationRequestDto dto, Long createurId);

    InvitationResponseDto repondreInvitation(Long invitationId, boolean accepte, Long utilisateurId);

    List<InvitationResponseDto> getMesInvitations(Long utilisateurId);

    List<InvitationResponseDto> getInvitationsByProjet(Long projetId, Long utilisateurId);

    void quitterProjet(Long projetId, Long utilisateurId);

    void retirerMembre(Long projetId, Long membreId, Long createurId);
}
