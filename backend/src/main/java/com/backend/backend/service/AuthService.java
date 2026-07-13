package com.backend.backend.service;

import com.backend.backend.dto.auth.LoginRequestDto;
import com.backend.backend.dto.auth.RegisterRequestDto;
import com.backend.backend.dto.utilisateur.UtilisateurResponseDto;

import java.util.Map;

public interface AuthService {

    UtilisateurResponseDto register(RegisterRequestDto dto);

    Map<String, String> login(LoginRequestDto dto);
}
