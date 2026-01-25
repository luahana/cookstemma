package com.cookstemma.cookstemma;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class CookstemmaApplication {

	public static void main(String[] args) {
		SpringApplication.run(CookstemmaApplication.class, args);
	}

}
