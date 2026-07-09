package com.backend.backend.service;

import com.backend.backend.dto.auth.LoginRequestDto;
import com.backend.backend.dto.auth.RegisterRequestDto;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;

public interface AuthService {

    UtilisateurResponseDto register(RegisterRequestDto dto);

    UtilisateurResponseDto login(LoginRequestDto dto);
}
