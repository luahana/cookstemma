package com.cookstemma.cookstemma.exception;

import io.sentry.Sentry;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * [401 Unauthorized]
     * 인증 및 인가 관련 예외 처리 (User not found, Token expired 등)
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgumentException(IllegalArgumentException e) {
        log.warn("Authentication/authorization exception: {}", e.getMessage());

        // AuthService 및 ImageService에서 발생하는 "User not found" 처리
        if (e.getMessage().contains("User not found") || e.getMessage().contains("Token")) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("code", "AUTH_REQUIRED", "message", e.getMessage()));
        }

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("code", "INVALID_INPUT", "message", e.getMessage()));
    }

    /**
     * [400 Bad Request]
     * @Valid를 사용한 DTO 유효성 검사 실패 시 발생
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidationExceptions(MethodArgumentNotValidException e) {
        Map<String, String> errors = new HashMap<>();
        e.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });

        log.warn("Validation failed: {}", errors);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("code", "VALIDATION_ERROR", "errors", errors));
    }

    /**
     * [400 Bad Request]
     * 파라미터 타입이 일치하지 않을 때 발생 (예: Enum 변환 실패)
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Map<String, String>> handleTypeMismatch(MethodArgumentTypeMismatchException e) {
        String message = String.format("Invalid value for parameter '%s'. Expected type: %s",
                e.getName(), e.getRequiredType().getSimpleName());

        log.warn("Type mismatch: {}", e.getValue());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("code", "TYPE_MISMATCH", "message", message));
    }

    /**
     * [400 Bad Request]
     * 필수 요청 파라미터가 누락되었을 때 발생
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, String>> handleMissingParams(MissingServletRequestParameterException e) {
        String message = String.format("Required parameter '%s' is missing.", e.getParameterName());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("code", "MISSING_PARAMETER", "message", message));
    }

    /**
     * [403 Forbidden]
     * 리소스에 대한 접근 권한이 없을 때 발생 (예: 다른 사용자의 로그 수정/삭제 시도)
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, String>> handleAccessDeniedException(AccessDeniedException e) {
        log.warn("Access denied: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(Map.of("code", "ACCESS_DENIED", "message", e.getMessage()));
    }

    /**
     * [413 Payload Too Large]
     * 이미지 등 파일 업로드 시 설정된 용량을 초과할 때 발생
     */
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String, String>> handleMaxSizeException(MaxUploadSizeExceededException e) {
        log.warn("File upload size exceeded");
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
                .body(Map.of("code", "FILE_TOO_LARGE", "message", "Maximum file upload size exceeded."));
    }

    /**
     * [500 Internal Server Error]
     * 그 외 정의되지 않은 모든 서버 내부 에러 처리
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneralException(Exception e) {
        log.error("Unexpected server error: ", e);

        // Capture unexpected errors to Sentry (only if configured)
        Sentry.captureException(e);

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("code", "SERVER_ERROR", "message", "An internal server error occurred. Please try again later."));
    }
}