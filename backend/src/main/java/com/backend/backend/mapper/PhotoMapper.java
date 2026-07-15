package com.backend.backend.mapper;

import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.entities.Photo;
import com.backend.backend.dto.photo.PhotoRequestDto;
import com.backend.backend.dto.photo.PhotoResponseDto;
import org.springframework.stereotype.Component;

@Component
public class PhotoMapper {

    public PhotoResponseDto toDto(Photo photo) {
        if (photo == null) {
            return null;
        }
        PhotoResponseDto dto = new PhotoResponseDto();
        dto.setId(photo.getId());
        dto.setCheminFichier(photo.getCheminFichier());
        dto.setDatePrise(photo.getDatePrise());
        dto.setAnnotationsDessin(photo.getAnnotationsDessin());
        dto.setThumbnailUrl(photo.getThumbnailUrl());
        
        if (photo.getFuite() != null) {
            dto.setFuiteId(photo.getFuite().getId());
        }
        
        return dto;
    }

    public Photo toEntity(PhotoRequestDto dto) {
        if (dto == null) {
            return null;
        }
        Photo photo = new Photo();
        photo.setCheminFichier(dto.getCheminFichier());
        photo.setDatePrise(dto.getDatePrise());
        photo.setAnnotationsDessin(dto.getAnnotationsDessin());
        photo.setThumbnailUrl(dto.getThumbnailUrl());
        
        if (dto.getFuiteId() != null) {
            Fuite fuite = new Fuite();
            fuite.setId(dto.getFuiteId());
            photo.setFuite(fuite);
        }
        
        return photo;
    }
}
