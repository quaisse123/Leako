package com.backend.backend.web;

import com.backend.backend.dto.photo.PhotoRequestDto;
import com.backend.backend.dto.photo.PhotoResponseDto;
import com.backend.backend.service.FileStorageService;
import com.backend.backend.service.PhotoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.MalformedURLException;
import java.nio.file.Path;
import java.util.List;

@CrossOrigin
@RestController
@RequestMapping("/api/photos")
@RequiredArgsConstructor
public class PhotoController {

    private final PhotoService service;
    private final FileStorageService fileStorageService;

    @PostMapping("/upload")
    public ResponseEntity<PhotoResponseDto> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam("fuiteId") Long fuiteId,
            @RequestParam(value = "datePrise", required = false) String datePrise,
            @RequestParam(value = "annotationsDessin", required = false) String annotationsDessin,
            @RequestParam(value = "thumbnail", required = false) MultipartFile thumbnailFile) {

        // Stocker le fichier
        String filename = fileStorageService.storeFile(file);

        // Générer la miniature : soit via ImageIO (images), soit via le fichier uploadé (vidéos)
        String thumbFilename = null;
        if (thumbnailFile != null && !thumbnailFile.isEmpty()) {
            // Miniature uploadée depuis le frontend (pour les vidéos)
            thumbFilename = FileStorageService.getThumbFilename(filename);
            fileStorageService.storeFile(thumbnailFile, thumbFilename);
        } else {
            // Générer automatiquement pour les images
            thumbFilename = fileStorageService.generateThumbnail(filename, 300);
        }

        // Construire le DTO
        PhotoRequestDto dto = new PhotoRequestDto();
        dto.setCheminFichier(filename);
        dto.setFuiteId(fuiteId);
        if (datePrise != null) {
            dto.setDatePrise(java.sql.Date.valueOf(datePrise.substring(0, 10)));
        }
        if (annotationsDessin != null) {
            dto.setAnnotationsDessin(annotationsDessin);
        }
        if (thumbFilename != null) {
            dto.setThumbnailUrl(thumbFilename);
        }

        PhotoResponseDto saved = service.createPhoto(dto);
        saved.setCheminFichier("/uploads/photos/" + filename);
        if (saved.getThumbnailUrl() != null) {
            saved.setThumbnailUrl("/uploads/photos/" + saved.getThumbnailUrl());
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PostMapping
    public ResponseEntity<PhotoResponseDto> create(@Valid @RequestBody PhotoRequestDto dto) {
        PhotoResponseDto saved = service.createPhoto(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @GetMapping
    public List<PhotoResponseDto> list(@RequestParam Long fuiteId) {
        List<PhotoResponseDto> photos = service.getPhotosByFuite(fuiteId);
        // Enrichir avec les URLs
        for (PhotoResponseDto photo : photos) {
            enrichPhotoUrls(photo);
        }
        return photos;
    }

    @GetMapping("/{id}")
    public PhotoResponseDto get(@PathVariable Long id) {
        PhotoResponseDto photo = service.getPhotoById(id);
        enrichPhotoUrls(photo);
        return photo;
    }

    private void enrichPhotoUrls(PhotoResponseDto photo) {
        String filename = photo.getCheminFichier();
        if (filename == null || filename.startsWith("/uploads/")) return;

        photo.setCheminFichier("/uploads/photos/" + filename);

        // thumbnailUrl déjà défini en DB (uploadé avec la vidéo) → préfixer
        String existingThumb = photo.getThumbnailUrl();
        if (existingThumb != null && !existingThumb.isEmpty() && !existingThumb.startsWith("/uploads/")) {
            photo.setThumbnailUrl("/uploads/photos/" + existingThumb);
        } else if (!isVideoFile(filename)) {
            // Générer pour les images (ancien comportement)
            photo.setThumbnailUrl("/uploads/photos/" + FileStorageService.getThumbFilename(filename));
        }
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        PhotoResponseDto photo = service.getPhotoById(id);
        // Extraire le nom du fichier depuis l'URL enrichie
        String filePath = photo.getCheminFichier();
        String prefix = "/uploads/photos/";
        if (filePath != null && filePath.startsWith(prefix)) {
            filePath = filePath.substring(prefix.length());
        }
        fileStorageService.deleteFile(filePath);
        service.deletePhoto(id);
    }

    /**
     * Sert les fichiers (photos et miniatures) depuis le dossier d'upload.
     * Retourne Resource directement pour que Spring gère les Range requests (206).
     */
    @GetMapping("/file/{filename:.+}")
    public ResponseEntity<Resource> serveFile(@PathVariable String filename) {
        try {
            Path filePath = fileStorageService.resolveFile(filename);
            UrlResource resource = new UrlResource(filePath.toUri());

            if (!resource.exists() || !resource.isReadable()) {
                return ResponseEntity.notFound().build();
            }

            String contentType = determineContentType(filename);
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                    .body(resource);

        } catch (MalformedURLException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    private String determineContentType(String filename) {
        String ext = filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
        return switch (ext) {
            case "jpg", "jpeg" -> "image/jpeg";
            case "png" -> "image/png";
            case "gif" -> "image/gif";
            case "webp" -> "image/webp";
            case "mp4" -> "video/mp4";
            case "mov" -> "video/quicktime";
            case "avi" -> "video/x-msvideo";
            case "mkv" -> "video/x-matroska";
            case "webm" -> "video/webm";
            default -> "application/octet-stream";
        };
    }

    private boolean isVideoFile(String filename) {
        String ext = filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
        return switch (ext) {
            case "mp4", "mov", "avi", "mkv", "webm" -> true;
            default -> false;
        };
    }
}
