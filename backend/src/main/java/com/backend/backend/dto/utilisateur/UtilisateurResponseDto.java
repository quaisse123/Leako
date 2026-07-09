package com.backend.backend.dto.utilisateur;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UtilisateurResponseDto {
    private Long id;
    private String nom;
    private String email;
}
