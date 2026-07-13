package com.backend.backend.service;

public interface PasswordService {
    String hashPassword(String rawPassword);
    boolean matches(String rawPassword, String hashedPassword);
}
