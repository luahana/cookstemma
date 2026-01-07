package com.pairingplanet.pairing_planet.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@Configuration
@EnableJpaAuditing // 여기에 붙입니다
public class JpaConfig {
}