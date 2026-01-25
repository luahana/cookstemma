package com.cookstemma.cookstemma.repository.bot;

import com.cookstemma.cookstemma.domain.entity.bot.BotCreatedFood;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BotCreatedFoodRepository extends JpaRepository<BotCreatedFood, Long> {

    /**
     * Get all food names created by a specific bot persona.
     */
    @Query("SELECT b.foodName FROM BotCreatedFood b WHERE b.personaName = :personaName")
    List<String> findFoodNamesByPersonaName(String personaName);

    /**
     * Check if a bot has already created a recipe for a specific food.
     */
    boolean existsByPersonaNameAndFoodNameIgnoreCase(String personaName, String foodName);
}
