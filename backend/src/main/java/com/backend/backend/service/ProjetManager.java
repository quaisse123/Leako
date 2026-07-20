package com.backend.backend.service;

import com.backend.backend.dao.entities.Projet;
import com.backend.backend.dao.entities.ProjetMembre;
import com.backend.backend.dao.entities.StatutInvitation;
import com.backend.backend.dao.entities.Utilisateur;
import com.backend.backend.dao.repositories.ProjetMembreRepository;
import com.backend.backend.dao.repositories.ProjetRepository;
import com.backend.backend.dao.repositories.UtilisateurRepository;
import com.backend.backend.dto.projet.InvitationRequestDto;
import com.backend.backend.dto.projet.InvitationResponseDto;
import com.backend.backend.dto.projet.ProjetRequestDto;
import com.backend.backend.dto.projet.ProjetResponseDto;
import com.backend.backend.mapper.ProjetMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
public class ProjetManager implements ProjetService {

    private final ProjetRepository projetRepository;
    private final ProjetMembreRepository membreRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final ProjetMapper projetMapper;

    // ─── PROJET CRUD ────────────────────────────────────────────────

    @Override
    @Transactional
    public ProjetResponseDto createProjet(ProjetRequestDto dto, Long createurId) {
        Utilisateur createur = utilisateurRepository.findById(createurId)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé avec l'ID : " + createurId));

        Projet projet = projetMapper.toEntity(dto, createur);
        projet = projetRepository.save(projet);

        // L'owner est automatiquement membre avec statut ACCEPTE
        ProjetMembre ownerMember = new ProjetMembre();
        ownerMember.setProjet(projet);
        ownerMember.setUtilisateur(createur);
        ownerMember.setStatut(StatutInvitation.ACCEPTE);
        ownerMember.setDateInvitation(new Date());
        ownerMember.setDateReponse(new Date());
        membreRepository.save(ownerMember);

        return projetMapper.toDto(projet);
    }

    @Override
    public ProjetResponseDto getProjetById(Long projetId, Long utilisateurId) {
        Projet projet = projetRepository.findById(projetId)
                .orElseThrow(() -> new RuntimeException("Projet non trouvé avec l'ID : " + projetId));

        verifierAcces(projetId, utilisateurId);

        return projetMapper.toDto(projet);
    }

    @Override
    public List<ProjetResponseDto> getMesProjets(Long utilisateurId) {
        // Projets où l'utilisateur est owner ou membre accepté
        List<Projet> enTantQueCreateur = projetRepository.findByCreateurId(utilisateurId);
        List<Projet> enTantQueMembre = projetRepository.findProjetsByMembreId(utilisateurId);

        return Stream.concat(enTantQueCreateur.stream(), enTantQueMembre.stream())
                .distinct()
                .map(projetMapper::toDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public ProjetResponseDto updateProjet(Long projetId, ProjetRequestDto dto, Long utilisateurId) {
        Projet projet = projetRepository.findById(projetId)
                .orElseThrow(() -> new RuntimeException("Projet non trouvé avec l'ID : " + projetId));

        if (!projet.getCreateur().getId().equals(utilisateurId)) {
            throw new RuntimeException("Seul le créateur du projet peut le modifier");
        }

        if (dto.getNom() != null) projet.setNom(dto.getNom());
        if (dto.getDescription() != null) projet.setDescription(dto.getDescription());

        projet = projetRepository.save(projet);
        return projetMapper.toDto(projet);
    }

    @Override
    @Transactional
    public void deleteProjet(Long projetId, Long utilisateurId) {
        Projet projet = projetRepository.findById(projetId)
                .orElseThrow(() -> new RuntimeException("Projet non trouvé avec l'ID : " + projetId));

        if (!projet.getCreateur().getId().equals(utilisateurId)) {
            throw new RuntimeException("Seul le créateur du projet peut le supprimer");
        }

        projetRepository.delete(projet);
    }

    // ─── INVITATIONS ────────────────────────────────────────────────

    @Override
    @Transactional
    public InvitationResponseDto inviterMembre(Long projetId, InvitationRequestDto dto, Long createurId) {
        Projet projet = projetRepository.findById(projetId)
                .orElseThrow(() -> new RuntimeException("Projet non trouvé avec l'ID : " + projetId));

        // Seul le créateur peut inviter
        if (!projet.getCreateur().getId().equals(createurId)) {
            throw new RuntimeException("Seul le créateur du projet peut inviter des membres");
        }

        Utilisateur invite = utilisateurRepository.findById(dto.getUtilisateurId())
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé avec l'ID : " + dto.getUtilisateurId()));

        // Vérifier que l'utilisateur n'est pas déjà membre accepté ou invité en attente
        var existing = membreRepository.findByProjetIdAndUtilisateurId(projetId, dto.getUtilisateurId());
        if (existing.isPresent()) {
            ProjetMembre existingMembre = existing.get();
            if (existingMembre.getStatut() == StatutInvitation.ACCEPTE) {
                throw new RuntimeException("Cet utilisateur est déjà membre du projet");
            }
            if (existingMembre.getStatut() == StatutInvitation.INVITE) {
                throw new RuntimeException("Cet utilisateur a déjà une invitation en attente pour ce projet");
            }
            // Si REFUSE, on ré-invite : on met à jour l'enregistrement existant
            existingMembre.setStatut(StatutInvitation.INVITE);
            existingMembre.setDateInvitation(new Date());
            existingMembre.setDateReponse(null);
            existingMembre = membreRepository.save(existingMembre);
            return toInvitationResponseDto(existingMembre);
        }

        ProjetMembre membre = new ProjetMembre();
        membre.setProjet(projet);
        membre.setUtilisateur(invite);
        membre.setStatut(StatutInvitation.INVITE);
        membre.setDateInvitation(new Date());
        membre = membreRepository.save(membre);

        return toInvitationResponseDto(membre);
    }

    @Override
    @Transactional
    public InvitationResponseDto repondreInvitation(Long invitationId, boolean accepte, Long utilisateurId) {
        ProjetMembre membre = membreRepository.findById(invitationId)
                .orElseThrow(() -> new RuntimeException("Invitation non trouvée avec l'ID : " + invitationId));

        if (!membre.getUtilisateur().getId().equals(utilisateurId)) {
            throw new RuntimeException("Cette invitation ne vous est pas adressée");
        }

        if (membre.getStatut() != StatutInvitation.INVITE) {
            throw new RuntimeException("Cette invitation a déjà été traitée");
        }

        membre.setStatut(accepte ? StatutInvitation.ACCEPTE : StatutInvitation.REFUSE);
        membre.setDateReponse(new Date());
        membre = membreRepository.save(membre);

        return toInvitationResponseDto(membre);
    }

    @Override
    public List<InvitationResponseDto> getMesInvitations(Long utilisateurId) {
        return membreRepository.findByUtilisateurIdAndStatut(utilisateurId, StatutInvitation.INVITE)
                .stream()
                .map(this::toInvitationResponseDto)
                .collect(Collectors.toList());
    }

    @Override
    public List<InvitationResponseDto> getInvitationsByProjet(Long projetId, Long utilisateurId) {
        // Seul le createur peut voir les invitations d'un projet
        Projet projet = projetRepository.findById(projetId)
                .orElseThrow(() -> new RuntimeException("Projet non trouvé avec l'ID : " + projetId));

        if (!projet.getCreateur().getId().equals(utilisateurId)) {
            throw new RuntimeException("Seul le créateur du projet peut voir les invitations");
        }

        return membreRepository.findByProjetId(projetId)
                .stream()
                .map(this::toInvitationResponseDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void quitterProjet(Long projetId, Long utilisateurId) {
        ProjetMembre membre = membreRepository.findByProjetIdAndUtilisateurId(projetId, utilisateurId)
                .orElseThrow(() -> new RuntimeException("Vous n'êtes pas membre de ce projet"));

        // L'owner ne peut pas quitter, il doit supprimer le projet
        Projet projet = projetRepository.findById(projetId)
                .orElseThrow(() -> new RuntimeException("Projet non trouvé"));
        if (projet.getCreateur().getId().equals(utilisateurId)) {
            throw new RuntimeException("Le créateur ne peut pas quitter le projet. Utilisez la suppression à la place.");
        }

        membreRepository.delete(membre);
    }

    @Override
    @Transactional
    public void retirerMembre(Long projetId, Long membreId, Long createurId) {
        Projet projet = projetRepository.findById(projetId)
                .orElseThrow(() -> new RuntimeException("Projet non trouvé"));

        if (!projet.getCreateur().getId().equals(createurId)) {
            throw new RuntimeException("Seul le créateur du projet peut retirer des membres");
        }

        if (createurId.equals(membreId)) {
            throw new RuntimeException("Le créateur ne peut pas se retirer lui-même. Utilisez la suppression du projet.");
        }

        ProjetMembre membre = membreRepository.findByProjetIdAndUtilisateurId(projetId, membreId)
                .orElseThrow(() -> new RuntimeException("Cet utilisateur n'est pas membre de ce projet"));

        membreRepository.delete(membre);
    }

    // ─── PRIVÉ ──────────────────────────────────────────────────────

    private void verifierAcces(Long projetId, Long utilisateurId) {
        boolean hasAccess = membreRepository.findByProjetIdAndUtilisateurId(projetId, utilisateurId)
                .filter(m -> m.getStatut() == StatutInvitation.ACCEPTE)
                .isPresent();
        if (!hasAccess) {
            throw new RuntimeException("Accès refusé — vous n'êtes pas membre de ce projet");
        }
    }

    private InvitationResponseDto toInvitationResponseDto(ProjetMembre pm) {
        InvitationResponseDto dto = new InvitationResponseDto();
        dto.setId(pm.getId());
        dto.setDateInvitation(pm.getDateInvitation());
        dto.setDateReponse(pm.getDateReponse());
        dto.setStatut(pm.getStatut().name());

        if (pm.getProjet() != null) {
            dto.setProjetId(pm.getProjet().getId());
            dto.setProjetNom(pm.getProjet().getNom());
            if (pm.getProjet().getCreateur() != null) {
                dto.setCreateurId(pm.getProjet().getCreateur().getId());
                dto.setCreateurNom(pm.getProjet().getCreateur().getNom());
            }
        }

        if (pm.getUtilisateur() != null) {
            dto.setUtilisateurId(pm.getUtilisateur().getId());
            dto.setUtilisateurNom(pm.getUtilisateur().getNom());
        }

        return dto;
    }
}
