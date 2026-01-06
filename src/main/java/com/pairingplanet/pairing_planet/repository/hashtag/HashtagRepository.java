package com.pairingplanet.pairing_planet.repository.hashtag;

import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface HashtagRepository extends JpaRepository<Hashtag, Long> {
    Optional<Hashtag> findByName(String name);

    // 이름 리스트로 한꺼번에 조회
    List<Hashtag> findByNameIn(List<String> names);

    // 자동완성용 검색 (대소문자 무시)
    List<Hashtag> findByNameContainingIgnoreCase(String name);
}
