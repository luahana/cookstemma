package com.cookstemma.cookstemma.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Slf4j
@Component
public class InternalApiKeyInterceptor implements HandlerInterceptor {

    @Value("${internal.api.key}") // application.yml에 정의된 키 사용
    private String internalApiKey;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String requestApiKey = request.getHeader("X-Internal-Api-Key");

        if (internalApiKey.equals(requestApiKey)) {
            return true;
        }
        log.error("봇 인증 실패! 요청된 키: {}, 설정된 키: {}", requestApiKey, internalApiKey);

        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid Internal API Key");
        return false;
    }
}