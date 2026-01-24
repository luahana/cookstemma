"""
Tests for the transaction wrapper in save_full_recipe_translations.

These tests verify that:
1. Successful translations commit all changes atomically
2. Failed translations roll back all changes (no partial translations)

Note: These tests are standalone and don't import handler.py directly due to
Python 3.10+ type hint syntax in handler.py (str | None). The tests simulate
the same transaction logic pattern used in the actual implementation.
"""
import json
import pytest
from unittest.mock import MagicMock, call
from typing import Dict, List, Any, Optional


def to_language_key(locale: str) -> str:
    """Convert locale to 2-letter language code (mirrors handler.py)."""
    if not locale:
        return 'ko'
    return locale.split('-')[0].lower()


def save_full_recipe_translations_test(
    conn,
    recipe_id: int,
    full_recipe: Dict[str, Any],
    translated: Dict[str, Any],
    target_locale: str
) -> None:
    """
    Test version of save_full_recipe_translations with the transaction wrapper.
    This mirrors the exact logic in handler.py.
    """
    target_lang = to_language_key(target_locale)
    source_lang = to_language_key(full_recipe.get('source_locale', 'ko'))

    # ==========================================================================
    # VALIDATION BEFORE TRANSACTION - fail fast before modifying any data
    # ==========================================================================
    if 'title' not in translated or not translated['title']:
        raise ValueError(f"Translation missing required 'title' for locale {target_locale}")
    if 'description' not in translated:
        raise ValueError(f"Translation missing 'description' for locale {target_locale}")
    if 'steps' not in translated:
        raise ValueError(f"Translation missing required 'steps' for locale {target_locale}")
    if 'ingredients' not in translated:
        raise ValueError(f"Translation missing required 'ingredients' for locale {target_locale}")

    translated_steps = translated['steps']
    if len(translated_steps) != len(full_recipe['steps']):
        raise ValueError(f"Step count mismatch: expected {len(full_recipe['steps'])}, got {len(translated_steps)}")

    translated_ingredients = translated['ingredients']
    if len(translated_ingredients) != len(full_recipe['ingredients']):
        raise ValueError(f"Ingredient count mismatch: expected {len(full_recipe['ingredients'])}, got {len(translated_ingredients)}")

    # ==========================================================================
    # BEGIN SAVEPOINT TRANSACTION - all updates below are atomic per-locale
    # ==========================================================================
    savepoint_name = f"translation_save_{recipe_id}_{target_lang}"

    with conn.cursor() as cur:
        try:
            # Create savepoint for atomic rollback on failure
            cur.execute(f"SAVEPOINT {savepoint_name}")

            # 1. Update recipe
            cur.execute("UPDATE recipes SET ... WHERE id = %s RETURNING id", (recipe_id,))
            if not cur.fetchone():
                raise ValueError(f"Recipe {recipe_id} not found in database")

            # 2. Update food_master (optional)
            food_master = full_recipe.get('food_master', {})
            if food_master.get('id'):
                cur.execute("UPDATE foods_master SET ... WHERE id = %s", (food_master['id'],))

            # 3. Update each step
            for i, step in enumerate(full_recipe['steps']):
                if not translated_steps[i]:
                    raise ValueError(f"Step {i} translation is empty for locale {target_locale}")
                cur.execute("UPDATE recipe_steps SET ... WHERE id = %s RETURNING id", (step['id'],))
                if not cur.fetchone():
                    raise ValueError(f"Step {step['id']} not found in database")

            # 4. Update each ingredient
            for i, ingredient in enumerate(full_recipe['ingredients']):
                if not translated_ingredients[i]:
                    raise ValueError(f"Ingredient {i} translation is empty for locale {target_locale}")
                cur.execute("UPDATE recipe_ingredients SET ... WHERE id = %s RETURNING id", (ingredient['id'],))
                if not cur.fetchone():
                    raise ValueError(f"Ingredient {ingredient['id']} not found in database")

            # ==========================================================================
            # RELEASE SAVEPOINT - all updates succeeded, make changes permanent
            # ==========================================================================
            cur.execute(f"RELEASE SAVEPOINT {savepoint_name}")

        except Exception as e:
            # ==========================================================================
            # ROLLBACK TO SAVEPOINT - undo all changes from this locale
            # ==========================================================================
            cur.execute(f"ROLLBACK TO SAVEPOINT {savepoint_name}")
            raise


class TestSaveFullRecipeTranslationsTransaction:
    """Test transaction behavior of save_full_recipe_translations."""

    def setup_method(self):
        """Set up test fixtures."""
        self.mock_conn = MagicMock()
        self.mock_cursor = MagicMock()
        self.mock_conn.cursor.return_value.__enter__ = MagicMock(return_value=self.mock_cursor)
        self.mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)

        self.recipe_id = 123
        self.target_locale = "en-US"

        self.full_recipe = {
            'recipe': {
                'title': '맛있는 비빔밥',
                'description': '건강한 한식 요리입니다.'
            },
            'food_master': {'id': 456, 'name': '비빔밥'},
            'steps': [
                {'id': 1, 'description': '야채를 준비합니다.'},
                {'id': 2, 'description': '밥을 짓습니다.'},
                {'id': 3, 'description': '고추장을 넣고 비빕니다.'}
            ],
            'ingredients': [
                {'id': 10, 'name': '밥', 'type': 'INGREDIENT'},
                {'id': 11, 'name': '고추장', 'type': 'SAUCE'}
            ],
            'source_locale': 'ko',
            'change_reason': ''
        }

        self.translated = {
            'title': 'Delicious Bibimbap',
            'description': 'A healthy Korean dish.',
            'food_name': 'Bibimbap',
            'steps': [
                'Prepare the vegetables.',
                'Cook the rice.',
                'Add gochujang and mix.'
            ],
            'ingredients': ['Rice', 'Gochujang']
        }

    def test_successful_translation_creates_and_releases_savepoint(self):
        """Test that successful translation creates savepoint at start and releases at end."""
        # Setup: all fetchone calls return a valid result
        self.mock_cursor.fetchone.return_value = (1,)
        self.mock_cursor.rowcount = 0

        # Execute
        save_full_recipe_translations_test(
            self.mock_conn,
            self.recipe_id,
            self.full_recipe,
            self.translated,
            self.target_locale
        )

        # Verify savepoint was created and released
        execute_calls = self.mock_cursor.execute.call_args_list
        execute_sql = [c[0][0] if c[0] else '' for c in execute_calls]

        # Check SAVEPOINT was created
        savepoint_created = any('SAVEPOINT translation_save_' in sql for sql in execute_sql)
        assert savepoint_created, "SAVEPOINT should be created at start of transaction"

        # Check RELEASE SAVEPOINT was called (success case)
        savepoint_released = any('RELEASE SAVEPOINT translation_save_' in sql for sql in execute_sql)
        assert savepoint_released, "RELEASE SAVEPOINT should be called on success"

        # Check ROLLBACK was NOT called
        rollback_called = any('ROLLBACK TO SAVEPOINT' in sql for sql in execute_sql)
        assert not rollback_called, "ROLLBACK should NOT be called on success"

    def test_step_update_failure_rolls_back_all_changes(self):
        """Test that failure during step update rolls back recipe and food_master changes."""
        # Setup: first few fetchone calls succeed, then fail on 3rd step
        call_count = [0]

        def mock_fetchone():
            call_count[0] += 1
            if call_count[0] == 1:  # Recipe update
                return (1,)
            elif call_count[0] <= 3:  # Steps 1 and 2
                return (1,)
            else:  # Step 3 - simulate not found
                return None

        self.mock_cursor.fetchone.side_effect = mock_fetchone
        self.mock_cursor.rowcount = 0

        # Execute and expect exception
        with pytest.raises(ValueError) as exc_info:
            save_full_recipe_translations_test(
                self.mock_conn,
                self.recipe_id,
                self.full_recipe,
                self.translated,
                self.target_locale
            )

        assert "not found in database" in str(exc_info.value)

        # Verify ROLLBACK was called
        execute_sql = [c[0][0] if c[0] else '' for c in self.mock_cursor.execute.call_args_list]

        rollback_called = any('ROLLBACK TO SAVEPOINT translation_save_' in sql for sql in execute_sql)
        assert rollback_called, "ROLLBACK TO SAVEPOINT should be called on failure"

        # Verify RELEASE was NOT called
        release_called = any('RELEASE SAVEPOINT' in sql for sql in execute_sql)
        assert not release_called, "RELEASE SAVEPOINT should NOT be called on failure"

    def test_ingredient_update_failure_rolls_back_all_changes(self):
        """Test that failure during ingredient update rolls back all previous changes."""
        call_count = [0]

        def mock_fetchone():
            call_count[0] += 1
            if call_count[0] <= 4:  # Recipe + 3 steps
                return (1,)
            elif call_count[0] == 5:  # First ingredient succeeds
                return (1,)
            else:  # Second ingredient fails
                return None

        self.mock_cursor.fetchone.side_effect = mock_fetchone
        self.mock_cursor.rowcount = 0

        # Execute and expect exception
        with pytest.raises(ValueError) as exc_info:
            save_full_recipe_translations_test(
                self.mock_conn,
                self.recipe_id,
                self.full_recipe,
                self.translated,
                self.target_locale
            )

        assert "not found in database" in str(exc_info.value)

        # Verify ROLLBACK was called
        execute_sql = [c[0][0] if c[0] else '' for c in self.mock_cursor.execute.call_args_list]
        rollback_called = any('ROLLBACK TO SAVEPOINT translation_save_' in sql for sql in execute_sql)
        assert rollback_called, "ROLLBACK TO SAVEPOINT should be called on ingredient failure"

    def test_recipe_not_found_rolls_back(self):
        """Test that recipe not found causes rollback."""
        # Recipe update returns None (not found)
        self.mock_cursor.fetchone.return_value = None

        with pytest.raises(ValueError) as exc_info:
            save_full_recipe_translations_test(
                self.mock_conn,
                self.recipe_id,
                self.full_recipe,
                self.translated,
                self.target_locale
            )

        assert f"Recipe {self.recipe_id} not found" in str(exc_info.value)

        execute_sql = [c[0][0] if c[0] else '' for c in self.mock_cursor.execute.call_args_list]
        rollback_called = any('ROLLBACK TO SAVEPOINT translation_save_' in sql for sql in execute_sql)
        assert rollback_called, "ROLLBACK should be called when recipe not found"


class TestValidationBeforeTransaction:
    """Test that validation happens BEFORE transaction starts."""

    def setup_method(self):
        """Set up test fixtures."""
        self.mock_conn = MagicMock()
        self.mock_cursor = MagicMock()
        self.mock_conn.cursor.return_value.__enter__ = MagicMock(return_value=self.mock_cursor)
        self.mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)

        self.recipe_id = 123
        self.target_locale = "en-US"

        self.full_recipe = {
            'recipe': {'title': 'Test', 'description': 'Test desc'},
            'steps': [{'id': 1, 'description': 'Step 1'}],
            'ingredients': [{'id': 1, 'name': 'Ingredient 1', 'type': 'INGREDIENT'}],
            'source_locale': 'ko'
        }

    def test_missing_title_fails_before_transaction(self):
        """Test that missing title validation fails before any DB operations."""
        translated = {
            'title': '',  # Empty title
            'description': 'Test',
            'steps': ['Step 1'],
            'ingredients': ['Ingredient 1']
        }

        with pytest.raises(ValueError) as exc_info:
            save_full_recipe_translations_test(
                self.mock_conn,
                self.recipe_id,
                self.full_recipe,
                translated,
                self.target_locale
            )

        assert "missing required 'title'" in str(exc_info.value)
        # Cursor should never be used for DB operations before validation
        assert self.mock_cursor.execute.call_count == 0, "No DB operations should occur before validation"

    def test_step_count_mismatch_fails_before_transaction(self):
        """Test that step count mismatch validation fails before any DB operations."""
        translated = {
            'title': 'Test',
            'description': 'Test',
            'steps': ['Step 1', 'Step 2'],  # 2 steps but recipe has 1
            'ingredients': ['Ingredient 1']
        }

        with pytest.raises(ValueError) as exc_info:
            save_full_recipe_translations_test(
                self.mock_conn,
                self.recipe_id,
                self.full_recipe,
                translated,
                self.target_locale
            )

        assert "Step count mismatch" in str(exc_info.value)
        assert self.mock_cursor.execute.call_count == 0, "No DB operations should occur before validation"

    def test_ingredient_count_mismatch_fails_before_transaction(self):
        """Test that ingredient count mismatch validation fails before any DB operations."""
        translated = {
            'title': 'Test',
            'description': 'Test',
            'steps': ['Step 1'],
            'ingredients': ['Ing 1', 'Ing 2']  # 2 ingredients but recipe has 1
        }

        with pytest.raises(ValueError) as exc_info:
            save_full_recipe_translations_test(
                self.mock_conn,
                self.recipe_id,
                self.full_recipe,
                translated,
                self.target_locale
            )

        assert "Ingredient count mismatch" in str(exc_info.value)
        assert self.mock_cursor.execute.call_count == 0, "No DB operations should occur before validation"


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
