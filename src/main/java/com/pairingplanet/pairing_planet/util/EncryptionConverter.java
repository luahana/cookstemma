package com.pairingplanet.pairing_planet.util;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

@Component
@Converter
public class EncryptionConverter implements AttributeConverter<String, String> {

    private static final String ALGORITHM = "AES/GCM/NoPadding";
    private final SecretKey secretKey;

    // application.yml의 app.security.encryption-key (Base64 encoded 32bytes)
    public EncryptionConverter(@Value("${security.encryption-key}") String keyString) {
        this.secretKey = new SecretKeySpec(Base64.getDecoder().decode(keyString), "AES");
    }

    @Override
    public String convertToDatabaseColumn(String attribute) {
        if (attribute == null) return null;
        try {
            byte[] iv = new byte[12]; // GCM 표준 IV 길이
            new SecureRandom().nextBytes(iv);

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, new GCMParameterSpec(128, iv));

            byte[] cipherText = cipher.doFinal(attribute.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(iv) + ":" + Base64.getEncoder().encodeToString(cipherText);
        } catch (Exception e) { throw new RuntimeException("Encrypt Error", e); }
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        if (dbData == null) return null;
        try {
            String[] parts = dbData.split(":");
            byte[] iv = Base64.getDecoder().decode(parts[0]);
            byte[] cipherText = Base64.getDecoder().decode(parts[1]);

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(128, iv));

            return new String(cipher.doFinal(cipherText), StandardCharsets.UTF_8);
        } catch (Exception e) { throw new RuntimeException("Decrypt Error", e); }
    }
}