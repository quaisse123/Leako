package com.backend.backend.service;

import com.backend.backend.dto.photo.PhotoRequestDto;
import com.backend.backend.dto.photo.PhotoResponseDto;
import java.util.List;

public interface PhotoService {

    PhotoResponseDto createPhoto(PhotoRequestDto dto);

    void deletePhoto(Long id);

    PhotoResponseDto getPhotoById(Long id);

    List<PhotoResponseDto> getPhotosByFuite(Long fuiteId);
}
