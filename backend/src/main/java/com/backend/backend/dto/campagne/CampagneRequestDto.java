package com.backend.backend.dto.campagne;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CampagneRequestDto {

    @NotBlank(message = "Le nom de la campagne est obligatoire")
    @Size(min = 2, max = 100, message = "Le nom de la campagne doit contenir entre 2 et 100 caractères")
    private String nom;

    private String description;

    private String zone;

    private Boolean estCloturee;

    @NotNull(message = "L'ID de l'utilisateur propriétaire est obligatoire")
    private Long createurId;

    private Long projetId;
}
