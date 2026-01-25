package com.cookstemma.cookstemma.dto.user;

import jakarta.validation.constraints.NotBlank;

/**
 * Request DTO for accepting legal terms (Terms of Service and Privacy Policy).
 * Sent when user agrees to terms during signup or when terms are updated.
 */
public record AcceptLegalTermsRequestDto(
        @NotBlank(message = "Terms version is required")
        String termsVersion,

        @NotBlank(message = "Privacy version is required")
        String privacyVersion,

        Boolean marketingAgreed
) {
}
