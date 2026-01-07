package com.pairingplanet.pairing_planet;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class PairingPlanetApplication {

	public static void main(String[] args) {
		SpringApplication.run(PairingPlanetApplication.class, args);
	}

}
