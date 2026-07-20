package com.backend.backend.web;

import com.backend.backend.dto.projet.InvitationRequestDto;
import com.backend.backend.dto.projet.InvitationResponseDto;
import com.backend.backend.dto.projet.ProjetRequestDto;
import com.backend.backend.dto.projet.ProjetResponseDto;
import com.backend.backend.service.ProjetService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin
@RestController
@RequestMapping("/api/projets")
@RequiredArgsConstructor
public class ProjetController {

    private final ProjetService projetService;

    // ─── CRUD PROJET ────────────────────────────────────────────────

    @PostMapping
    public ResponseEntity<ProjetResponseDto> create(
            @Valid @RequestBody ProjetRequestDto dto,
            @RequestParam Long createurId
    ) {
        ProjetResponseDto saved = projetService.createProjet(dto, createurId);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @GetMapping("/{id}")
    public ProjetResponseDto get(
            @PathVariable Long id,
            @RequestParam Long utilisateurId
    ) {
        return projetService.getProjetById(id, utilisateurId);
    }

    @GetMapping
    public List<ProjetResponseDto> getMesProjets(
            @RequestParam Long utilisateurId
    ) {
        return projetService.getMesProjets(utilisateurId);
    }

    @PutMapping("/{id}")
    public ProjetResponseDto update(
            @PathVariable Long id,
            @Valid @RequestBody ProjetRequestDto dto,
            @RequestParam Long utilisateurId
    ) {
        return projetService.updateProjet(id, dto, utilisateurId);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
            @PathVariable Long id,
            @RequestParam Long utilisateurId
    ) {
        projetService.deleteProjet(id, utilisateurId);
    }

    // ─── INVITATIONS ────────────────────────────────────────────────

    @PostMapping("/{id}/invitations")
    public ResponseEntity<InvitationResponseDto> inviter(
            @PathVariable Long id,
            @Valid @RequestBody InvitationRequestDto dto,
            @RequestParam Long createurId
    ) {
        InvitationResponseDto invitation = projetService.inviterMembre(id, dto, createurId);
        return ResponseEntity.status(HttpStatus.CREATED).body(invitation);
    }

    @GetMapping("/invitations")
    public List<InvitationResponseDto> getMesInvitations(
            @RequestParam Long utilisateurId
    ) {
        return projetService.getMesInvitations(utilisateurId);
    }

    @GetMapping("/{id}/invitations")
    public List<InvitationResponseDto> getInvitationsByProjet(
            @PathVariable Long id,
            @RequestParam Long utilisateurId
    ) {
        return projetService.getInvitationsByProjet(id, utilisateurId);
    }

    @PutMapping("/invitations/{invitationId}")
    public InvitationResponseDto repondreInvitation(
            @PathVariable Long invitationId,
            @RequestParam boolean accepte,
            @RequestParam Long utilisateurId
    ) {
        return projetService.repondreInvitation(invitationId, accepte, utilisateurId);
    }

    @PostMapping("/{id}/quitter")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void quitter(
            @PathVariable Long id,
            @RequestParam Long utilisateurId
    ) {
        projetService.quitterProjet(id, utilisateurId);
    }

    @DeleteMapping("/{id}/membres/{membreId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void retirerMembre(
            @PathVariable Long id,
            @PathVariable Long membreId,
            @RequestParam Long createurId
    ) {
        projetService.retirerMembre(id, membreId, createurId);
    }
}
