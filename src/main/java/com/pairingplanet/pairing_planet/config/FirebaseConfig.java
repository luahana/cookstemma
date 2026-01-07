package com.pairingplanet.pairing_planet.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${firebase.credentials:}")
    private String firebaseCredentials;

    @PostConstruct
    public void init() {
        try {
            InputStream serviceAccount;

            if (firebaseCredentials != null && !firebaseCredentials.isEmpty() && !firebaseCredentials.equals("{}")) {
                // Load from environment variable (AWS)
                serviceAccount = new ByteArrayInputStream(firebaseCredentials.getBytes(StandardCharsets.UTF_8));
                log.info("Loading Firebase credentials from environment variable");
            } else {
                // Load from classpath file (local dev)
                ClassPathResource resource = new ClassPathResource("firebase-service-account.json");
                if (!resource.exists()) {
                    log.warn("Firebase credentials not found, skipping Firebase initialization");
                    return;
                }
                serviceAccount = resource.getInputStream();
                log.info("Loading Firebase credentials from classpath");
            }

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                log.info("Firebase Admin SDK has been initialized successfully.");
            }
        } catch (IOException e) {
            log.error("Firebase initialization error: {}", e.getMessage());
            log.warn("Continuing without Firebase - push notifications will not work");
        }
    }
}