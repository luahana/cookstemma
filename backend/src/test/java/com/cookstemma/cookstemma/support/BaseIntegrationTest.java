package com.cookstemma.cookstemma.support;

import com.cookstemma.cookstemma.config.MockExternalServicesConfig;
import com.cookstemma.cookstemma.config.TestAsyncConfig;
import com.cookstemma.cookstemma.config.TestContainersConfig;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({TestContainersConfig.class, MockExternalServicesConfig.class, TestAsyncConfig.class})
@Transactional
public abstract class BaseIntegrationTest {
    // Common test utilities and setup methods can be added here
}
