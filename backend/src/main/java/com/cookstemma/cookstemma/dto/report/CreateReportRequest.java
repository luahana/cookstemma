package com.cookstemma.cookstemma.dto.report;

import com.cookstemma.cookstemma.domain.enums.ReportReason;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateReportRequest(
        @NotNull(message = "Report reason is required")
        ReportReason reason,

        @Size(max = 1000, message = "Description must not exceed 1000 characters")
        String description
) {}
