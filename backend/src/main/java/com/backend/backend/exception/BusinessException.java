package com.backend.backend.exception;

import org.springframework.http.HttpStatus;

/**
 * Exception métier renvoyée au client avec un message user-friendly
 * et un statut HTTP approprié.
 */
public class BusinessException extends RuntimeException {

    private final HttpStatus status;

    public BusinessException(String message) {
        this(message, HttpStatus.BAD_REQUEST);
    }

    public BusinessException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
