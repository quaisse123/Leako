package com.backend.backend.service;

import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.entities.Photo;
import com.backend.backend.dao.repositories.FuiteRepository;
import com.backend.backend.dao.repositories.PhotoRepository;
import com.backend.backend.dto.photo.PhotoRequestDto;
import com.backend.backend.dto.photo.PhotoResponseDto;
import com.backend.backend.mapper.PhotoMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PhotoManager implements PhotoService {

    private final PhotoRepository photoRepository;
    private final FuiteRepository fuiteRepository;
    private final PhotoMapper photoMapper;

    @Override
    public PhotoResponseDto createPhoto(PhotoRequestDto dto) {
        Photo photo = photoMapper.toEntity(dto);

        if (dto.getFuiteId() != null) {
            Fuite fuite = fuiteRepository.findById(dto.getFuiteId())
                .orElseThrow(() -> new RuntimeException("Fuite non trouvée avec l'ID : " + dto.getFuiteId()));
            photo.setFuite(fuite);
        }

        photo = photoRepository.save(photo);
        return photoMapper.toDto(photo);
    }

    @Override
    public void deletePhoto(Long id) {
        if (!photoRepository.existsById(id)) {
            throw new RuntimeException("Photo non trouvée avec l'ID : " + id);
        }
        photoRepository.deleteById(id);
    }

    @Override
    public PhotoResponseDto getPhotoById(Long id) {
        Photo photo = photoRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Photo non trouvée avec l'ID : " + id));
        return photoMapper.toDto(photo);
    }

    @Override
    public List<PhotoResponseDto> getPhotosByFuite(Long fuiteId) {
        return photoRepository.findByFuiteId(fuiteId).stream()
            .map(photoMapper::toDto)
            .collect(Collectors.toList());
    }
}
