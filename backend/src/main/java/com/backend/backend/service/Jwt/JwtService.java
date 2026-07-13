package com.backend.backend.service.Jwt;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

@Service
public class JwtService {

    @Value("${jwtSecretKey}")
    private String mySecretKey;

    // Génère un JWT avec des claims personnalisés et une durée de validité
    public String generateToken(Map<String, Object> claims, long durationMillis, String subject) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + durationMillis);

        String token = Jwts.builder()
                .setClaims(claims)
                .setSubject(subject)
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(Keys.hmacShaKeyFor(mySecretKey.getBytes()), SignatureAlgorithm.HS256)
                .compact();

        return token;
    }

    // Valide le token JWT (signature, expiration, etc.)
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder()
                    .setSigningKey(Keys.hmacShaKeyFor(mySecretKey.getBytes()))
                    .build()
                    .parseClaimsJws(token);
            return true;
        } catch (io.jsonwebtoken.JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    // Extrait les claims du token JWT
    public Map<String, Object> extractClaims(String token) {
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(Keys.hmacShaKeyFor(mySecretKey.getBytes()))
                .build()
                .parseClaimsJws(token)
                .getBody();
        return new HashMap<>(claims);
    }

    // Rafraîchit les tokens à partir d'un refresh token valide
    public Map<String, String> refreshTokens(String refreshToken, long accessDuration, long refreshDuration) {
        if (!validateToken(refreshToken)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Expired or invalid refresh token");
        }
        Map<String, Object> claims = extractClaims(refreshToken);
        String subject = (String) claims.get("sub");
        if (subject == null && claims.containsKey("email")) {
            subject = (String) claims.get("email");
        }
        if (subject == null) {
            throw new RuntimeException("Impossible de déterminer le sujet du token");
        }
        claims.remove("sub");
        claims.remove("iat");
        claims.remove("exp");
        String newAccessToken = generateToken(claims, accessDuration, subject);
        String newRefreshToken = generateToken(claims, refreshDuration, subject);

        Map<String, String> tokens = new HashMap<>();
        tokens.put("accessToken", newAccessToken);
        tokens.put("refreshToken", newRefreshToken);
        return tokens;
    }
}
