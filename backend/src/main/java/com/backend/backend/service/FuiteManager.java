package com.backend.backend.service;

import com.backend.backend.dao.entities.Campagne;
import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.repositories.CampagneRepository;
import com.backend.backend.dao.repositories.FuiteRepository;
import com.backend.backend.dto.fuite.FuiteRequestDto;
import com.backend.backend.dto.fuite.FuiteResponseDto;
import com.backend.backend.mapper.FuiteMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FuiteManager implements FuiteService {

    private final FuiteRepository fuiteRepository;
    private final CampagneRepository campagneRepository;
    private final FuiteMapper fuiteMapper;

    @Override
    public FuiteResponseDto createFuite(FuiteRequestDto dto) {
        Fuite fuite = fuiteMapper.toEntity(dto);

        if (dto.getCampagneId() != null) {
            Campagne campagne = campagneRepository.findById(dto.getCampagneId())
                .orElseThrow(() -> new RuntimeException("Campagne non trouvée avec l'ID : " + dto.getCampagneId()));
            fuite.setCampagne(campagne);
        }

        // Garantir l'unicité du numeroTag : si le tag fourni existe déjà,
        // générer automatiquement un tag unique basé sur le préfixe.
        if (fuite.getNumeroTag() != null && !fuite.getNumeroTag().isBlank()) {
            String tag = fuite.getNumeroTag();
            if (fuiteRepository.existsByNumeroTag(tag)) {
                tag = genererTagUnique(tag);
                fuite.setNumeroTag(tag);
            }
        }

        fuite = fuiteRepository.save(fuite);
        return fuiteMapper.toDto(fuite);
    }

    /**
     * Génère un tag unique en incrémentant le suffixe numérique du tag fourni.
     * Ex : "TAG-IJL-1-008" existe déjà -> essaie "TAG-IJL-1-009", "TAG-IJL-1-010", ...
     */
    private String genererTagUnique(String tagExistant) {
        // Extraire le préfixe (tout sauf le dernier segment numérique)
        int lastDash = tagExistant.lastIndexOf('-');
        if (lastDash <= 0) {
            // Pas de suffixe numérique identifiable, on ajoute un suffixe
            String base = tagExistant;
            int n = 1;
            while (fuiteRepository.existsByNumeroTag(base + "-" + String.format("%03d", n))) {
                n++;
            }
            return base + "-" + String.format("%03d", n);
        }

        String prefix = tagExistant.substring(0, lastDash + 1); // inclut le "-"
        String suffixe = tagExistant.substring(lastDash + 1);
        int numero;
        try {
            numero = Integer.parseInt(suffixe);
        } catch (NumberFormatException e) {
            numero = 0;
        }

        // Incrémenter jusqu'à trouver un tag libre
        while (fuiteRepository.existsByNumeroTag(prefix + String.format("%03d", numero))) {
            numero++;
        }
        return prefix + String.format("%03d", numero);
    }

    @Override
    public FuiteResponseDto updateFuite(Long id, FuiteRequestDto dto) {
        Fuite fuite = fuiteRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Fuite non trouvée avec l'ID : " + id));

        fuite.setNumeroTag(dto.getNumeroTag());
        fuite.setDateDetection(dto.getDateDetection());
        fuite.setStatut(dto.getStatut());
        fuite.setPressionBar(dto.getPressionBar());
        fuite.setDiametreOrifice(dto.getDiametreOrifice());
        fuite.setTypeVapeur(dto.getTypeVapeur());
        fuite.setGpsLatitude(dto.getGpsLatitude());
        fuite.setGpsLongitude(dto.getGpsLongitude());
        fuite.setZone(dto.getZone());
        fuite.setDescription(dto.getDescription());
        fuite.setCoutAnnuelEstime(dto.getCoutAnnuelEstime());

        fuite = fuiteRepository.save(fuite);
        return fuiteMapper.toDto(fuite);
    }

    @Override
    public void deleteFuite(Long id) {
        if (!fuiteRepository.existsById(id)) {
            throw new RuntimeException("Fuite non trouvée avec l'ID : " + id);
        }
        fuiteRepository.deleteById(id);
    }

    @Override
    public List<FuiteResponseDto> getAllFuites() {
        return fuiteRepository.findAll().stream()
            .map(fuiteMapper::toDto)
            .collect(Collectors.toList());
    }

    @Override
    public FuiteResponseDto getFuiteById(Long id) {
        Fuite fuite = fuiteRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Fuite non trouvée avec l'ID : " + id));
        return fuiteMapper.toDto(fuite);
    }

    @Override
    public List<FuiteResponseDto> getFuitesByCampagne(Long campagneId) {
        return fuiteRepository.findByCampagneId(campagneId).stream()
            .map(fuiteMapper::toDto)
            .collect(Collectors.toList());
    }

    @Override
    public List<FuiteResponseDto> getFuitesByUtilisateur(Long utilisateurId) {
        return fuiteRepository.findByCreateurId(utilisateurId).stream()
            .map(fuiteMapper::toDto)
            .collect(Collectors.toList());
    }

    @Override
    public List<FuiteResponseDto> getFuitesByProjetId(Long projetId) {
        return fuiteRepository.findByProjetId(projetId).stream()
            .map(fuiteMapper::toDto)
            .collect(Collectors.toList());
    }

    @Override
    public String genererProchainTag(String campagneNom, Long campagneId) {
        // Extraire les initiales du nom de la campagne
        String initiales = extraireInitiales(campagneNom);
        String prefix = "TAG-" + initiales + "-" + campagneId + "-";

        // Compter les tags existants avec ce préfixe unique (initiales + campagneId)
        long count = fuiteRepository.countByNumeroTagStartingWith(prefix);

        // Générer le prochain numéro (001, 002, ...)
        String numero = String.format("%03d", count + 1);
        String tag = prefix + numero;

        // Vérifier l'unicité (au cas où)
        while (fuiteRepository.existsByNumeroTag(tag)) {
            count++;
            numero = String.format("%03d", count + 1);
            tag = prefix + numero;
        }

        return tag;
    }

    private String extraireInitiales(String nom) {
        if (nom == null || nom.isBlank()) return "XX";
        String initiales = java.util.Arrays.stream(nom.trim().split("\\s+"))
            .filter(mot -> mot.length() > 2)
            .map(mot -> String.valueOf(Character.toUpperCase(mot.charAt(0))))
            .collect(Collectors.joining());
        if (initiales.isEmpty()) {
            // Fallback : prendre la 1ère lettre de chaque mot
            initiales = java.util.Arrays.stream(nom.trim().split("\\s+"))
                .map(mot -> String.valueOf(Character.toUpperCase(mot.charAt(0))))
                .collect(Collectors.joining());
        }
        return initiales.length() > 3 ? initiales.substring(0, 3) : initiales;
    }
}
