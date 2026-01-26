package com.cookstemma.cookstemma.controller;

import io.sentry.Sentry;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Controller for testing Sentry integration.
 * Admin-only endpoint to verify error tracking is working.
 */
@RestController
@RequestMapping("/api/v1/admin/sentry")
public class SentryTestController {

    @PostMapping("/test")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> testSentry() {
        Exception testException = new RuntimeException("Sentry test error from backend API");
        String eventId = Sentry.captureException(testException).toString();

        return ResponseEntity.ok(Map.of(
            "message", "Sentry test error sent",
            "eventId", eventId
        ));
    }
}
