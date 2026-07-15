package com.backend.backend.service;

import com.backend.backend.config.FileStorageConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FileStorageService {

    private final FileStorageConfig fileStorageConfig;

    /**
     * Sauvegarde un fichier uploadé et retourne le chemin relatif.
     * Exemple de retour : "uploads/photos/abc123.jpg"
     */
    public String storeFile(MultipartFile file) {
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String filename = UUID.randomUUID().toString() + extension;
        return storeFile(file, filename);
    }

    /**
     * Sauvegarde un fichier avec un nom spécifique.
     */
    public String storeFile(MultipartFile file, String filename) {
        try {
            Path targetLocation = fileStorageConfig.getUploadPath().resolve(filename);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
            return filename;
        } catch (IOException e) {
            throw new RuntimeException("Impossible de stocker le fichier " + filename, e);
        }
    }

    /**
     * Sauvegarde un fichier depuis un InputStream.
     */
    public String storeFile(InputStream inputStream, String filename) {
        try {
            Path targetLocation = fileStorageConfig.getUploadPath().resolve(filename);
            Files.copy(inputStream, targetLocation, StandardCopyOption.REPLACE_EXISTING);
            return filename;
        } catch (IOException e) {
            throw new RuntimeException("Impossible de stocker le fichier " + filename, e);
        }
    }

    /**
     * Génère une miniature pour une image et la sauvegarde.
     * Retourne le nom du fichier miniature.
     */
    public String generateThumbnail(String filename, int maxSize) {
        try {
            Path sourcePath = fileStorageConfig.getUploadPath().resolve(filename);
            BufferedImage original = ImageIO.read(sourcePath.toFile());
            if (original == null) return null;

            int width = original.getWidth();
            int height = original.getHeight();

            if (width <= maxSize && height <= maxSize) {
                // L'image est déjà plus petite que la miniature
                return filename;
            }

            double ratio = (double) maxSize / Math.max(width, height);
            int newWidth = (int) (width * ratio);
            int newHeight = (int) (height * ratio);

            java.awt.Image scaled = original.getScaledInstance(newWidth, newHeight, java.awt.Image.SCALE_SMOOTH);
            BufferedImage thumbnail = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_RGB);
            thumbnail.getGraphics().drawImage(scaled, 0, 0, null);

            String thumbFilename = getThumbFilename(filename);
            Path thumbPath = fileStorageConfig.getUploadPath().resolve(thumbFilename);

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(thumbnail, "JPEG", baos);
            Files.write(thumbPath, baos.toByteArray());

            return thumbFilename;
        } catch (IOException e) {
            // Silencieux : la miniature n'est pas critique
            return null;
        }
    }

    /**
     * Retourne le nom du fichier miniature.
     */
    public static String getThumbFilename(String filename) {
        int dot = filename.lastIndexOf('.');
        if (dot > 0) {
            return filename.substring(0, dot) + "_thumb.jpg";
        }
        return filename + "_thumb.jpg";
    }

    /**
     * Supprime un fichier.
     */
    public void deleteFile(String filename) {
        try {
            Path filePath = fileStorageConfig.getUploadPath().resolve(filename);
            Files.deleteIfExists(filePath);

            // Supprime aussi la miniature si elle existe
            String thumbFilename = getThumbFilename(filename);
            Path thumbPath = fileStorageConfig.getUploadPath().resolve(thumbFilename);
            Files.deleteIfExists(thumbPath);
        } catch (IOException e) {
            // Silencieux
        }
    }

    /**
     * Résout le chemin complet d'un fichier.
     */
    public Path resolveFile(String filename) {
        return fileStorageConfig.getUploadPath().resolve(filename);
    }
}
