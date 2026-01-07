package com.pairingplanet.pairing_planet.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final InternalApiKeyInterceptor internalApiKeyInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // /internal/api/ 로 시작하는 모든 요청에 대해 API Key 인터셉터 적용
        registry.addInterceptor(internalApiKeyInterceptor)
                .addPathPatterns("/internal/api/**");
    }
}