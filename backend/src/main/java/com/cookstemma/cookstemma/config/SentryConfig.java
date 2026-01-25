package com.cookstemma.cookstemma.config;

import io.sentry.Hint;
import io.sentry.SentryEvent;
import io.sentry.SentryOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.servlet.NoHandlerFoundException;

/**
 * Sentry configuration for error monitoring.
 * Only active when SENTRY_DSN is provided (production environment).
 *
 * Note: Uses Spring Boot auto-configuration from sentry-spring-boot-starter-jakarta.
 * Do NOT use @EnableSentry as it conflicts with the auto-configuration.
 */
@Slf4j
@Configuration
@ConditionalOnProperty(name = "sentry.dsn", matchIfMissing = false)
public class SentryConfig {

    @Bean
    public SentryOptions.BeforeSendCallback beforeSendCallback() {
        return (event, hint) -> filterEvent(event, hint);
    }

    /**
     * Filter events before sending to Sentry.
     * Returns null to drop the event, or the event to send it.
     */
    private SentryEvent filterEvent(SentryEvent event, Hint hint) {
        Throwable throwable = event.getThrowable();

        if (throwable == null) {
            return event;
        }

        // Don't send client errors (4xx) to Sentry - these are expected
        if (throwable instanceof IllegalArgumentException) {
            return null;
        }

        // Don't send access denied errors - these are expected authorization failures
        if (throwable instanceof AccessDeniedException) {
            return null;
        }

        // Don't send 404 errors
        if (throwable instanceof NoHandlerFoundException) {
            return null;
        }

        return event;
    }
}
