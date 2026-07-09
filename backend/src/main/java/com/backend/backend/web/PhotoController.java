package com.backend.backend.web;

import com.backend.backend.dto.photo.PhotoRequestDto;
import com.backend.backend.dto.photo.PhotoResponseDto;
import com.backend.backend.service.PhotoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@CrossOrigin
@RestController
@RequestMapping("/api/photos")
@RequiredArgsConstructor
public class PhotoController {

    private final PhotoService service;

    @PostMapping
    public ResponseEntity<PhotoResponseDto> create(@Valid @RequestBody PhotoRequestDto dto) {
        PhotoResponseDto saved = service.createPhoto(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @GetMapping
    public List<PhotoResponseDto> list(@RequestParam Long fuiteId) {
        return service.getPhotosByFuite(fuiteId);
    }

    @GetMapping("/{id}")
    public PhotoResponseDto get(@PathVariable Long id) {
        return service.getPhotoById(id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.deletePhoto(id);
    }
}
