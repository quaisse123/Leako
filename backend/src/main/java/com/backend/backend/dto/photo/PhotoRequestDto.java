package com.backend.backend.dto.photo;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PhotoRequestDto {

    @NotBlank(message = "Le chemin du fichier est obligatoire")
    private String cheminFichier;

    private Date datePrise;

    private String annotationsDessin;

    @NotNull(message = "L'ID de la fuite est obligatoire")
    private Long fuiteId;
}
