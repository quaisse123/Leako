package com.backend.backend.dto.photo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PhotoResponseDto {
    private Long id;
    private String cheminFichier;
    private String thumbnailUrl;
    private Date datePrise;
    private String annotationsDessin;
    private Long fuiteId;
}
