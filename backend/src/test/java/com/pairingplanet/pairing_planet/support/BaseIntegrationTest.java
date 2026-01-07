package com.pairingplanet.pairing_planet.support;

import com.pairingplanet.pairing_planet.config.MockExternalServicesConfig;
import com.pairingplanet.pairing_planet.config.TestContainersConfig;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({TestContainersConfig.class, MockExternalServicesConfig.class})
@Transactional
public abstract class BaseIntegrationTest {
    // Common test utilities and setup methods can be added here
}
