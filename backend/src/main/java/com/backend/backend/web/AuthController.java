package com.backend.backend.web;

import com.backend.backend.dto.auth.LoginRequestDto;
import com.backend.backend.dto.auth.RegisterRequestDto;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;
import com.backend.backend.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@CrossOrigin
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService service;

    @PostMapping("/register")
    public ResponseEntity<UtilisateurResponseDto> register(@Valid @RequestBody RegisterRequestDto dto) {
        UtilisateurResponseDto saved = service.register(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PostMapping("/login")
    public UtilisateurResponseDto login(@Valid @RequestBody LoginRequestDto dto) {
        return service.login(dto);
    }
}
