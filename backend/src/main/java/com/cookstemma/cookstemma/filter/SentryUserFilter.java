package com.cookstemma.cookstemma.filter;

import com.cookstemma.cookstemma.security.UserPrincipal;
import io.sentry.Sentry;
import io.sentry.protocol.User;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Filter that captures authenticated user context for Sentry.
 * Sets the user information on each request so errors can be associated with users.
 * Only active when Sentry DSN is configured (production/staging).
 *
 * Named 'customSentryUserFilter' to avoid conflict with Sentry's auto-configured 'sentryUserFilter'.
 */
@Component("customSentryUserFilter")
@Slf4j
@ConditionalOnProperty(name = "sentry.dsn", matchIfMissing = false)
public class SentryUserFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        try {
            setUserContext();
            filterChain.doFilter(request, response);
        } finally {
            // Clear user context after request to prevent leaking to other requests
            Sentry.configureScope(scope -> scope.setUser(null));
        }
    }

    /**
     * Set Sentry user context from authenticated user.
     * Uses public ID (not internal ID) for privacy.
     */
    private void setUserContext() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        if (auth != null && auth.getPrincipal() instanceof UserPrincipal userPrincipal) {
            User sentryUser = new User();
            // Use public ID for privacy - don't expose internal database IDs
            sentryUser.setId(userPrincipal.getPublicId().toString());
            sentryUser.setUsername(userPrincipal.getUsername());

            Sentry.configureScope(scope -> scope.setUser(sentryUser));
        }
    }
}
