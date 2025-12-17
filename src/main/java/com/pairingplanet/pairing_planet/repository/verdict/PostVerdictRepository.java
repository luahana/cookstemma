package com.pairingplanet.pairing_planet.repository.verdict;

import com.pairingplanet.pairing_planet.domain.entity.verdict.PostVerdictId;
import com.pairingplanet.pairing_planet.domain.entity.verdict.PostVerdict;
import org.springframework.data.jpa.repository.JpaRepository;

// 복합키(EmbeddedId)를 쓰지만, 편의를 위해 User, Post 객체로 조회하는 메서드 제공

public interface PostVerdictRepository extends JpaRepository<PostVerdict, PostVerdictId> {

}