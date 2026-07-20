package com.backend.backend.web;

import com.backend.backend.dto.fuite_message.FuiteMessageRequestDto;
import com.backend.backend.dto.fuite_message.FuiteMessageResponseDto;
import com.backend.backend.service.FileStorageService;
import com.backend.backend.service.FuiteMessageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@CrossOrigin
@RestController
@RequestMapping("/api/fuites/{fuiteId}/messages")
@RequiredArgsConstructor
public class FuiteMessageController {

    private final FuiteMessageService fuiteMessageService;
    private final FileStorageService fileStorageService;

    @GetMapping
    public ResponseEntity<List<FuiteMessageResponseDto>> getMessages(
            @PathVariable Long fuiteId) {
        return ResponseEntity.ok(fuiteMessageService.getMessagesByFuite(fuiteId));
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<FuiteMessageResponseDto> createMessage(
            @PathVariable Long fuiteId,
            @Valid @RequestBody FuiteMessageRequestDto dto) {
        dto.setFuiteId(fuiteId);
        FuiteMessageResponseDto saved = fuiteMessageService.createMessage(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PostMapping(value = "/with-audio", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<FuiteMessageResponseDto> createMessageWithAudio(
            @PathVariable Long fuiteId,
            @RequestParam("utilisateurId") Long utilisateurId,
            @RequestParam(value = "contenuTexte", required = false) String contenuTexte,
            @RequestParam("audio") MultipartFile audioFile,
            @RequestParam(value = "dureeAudioSecondes", required = false) Integer dureeAudioSecondes) {

        // Stocker le fichier audio
        String audioFilename = fileStorageService.storeFile(audioFile);

        FuiteMessageRequestDto dto = new FuiteMessageRequestDto();
        dto.setFuiteId(fuiteId);
        dto.setUtilisateurId(utilisateurId);
        dto.setContenuTexte(contenuTexte);
        dto.setCheminAudio("uploads/photos/" + audioFilename);
        dto.setDureeAudioSecondes(dureeAudioSecondes);

        FuiteMessageResponseDto saved = fuiteMessageService.createMessage(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMessage(
            @PathVariable Long fuiteId,
            @PathVariable Long id) {
        fuiteMessageService.deleteMessage(id);
        return ResponseEntity.noContent().build();
    }
}
