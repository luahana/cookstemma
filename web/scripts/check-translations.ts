/**
 * Translation Validation Script
 *
 * Validates that all translation files have matching keys with the source (en.json).
 * Run with: npx tsx scripts/check-translations.ts
 */

import * as fs from 'fs';
import * as path from 'path';

const MESSAGES_DIR = path.join(__dirname, '../messages');
const SOURCE_LOCALE = 'en';

interface TranslationObject {
  [key: string]: string | TranslationObject;
}

function getAllKeys(obj: TranslationObject, prefix = ''): string[] {
  return Object.entries(obj).flatMap(([key, value]) => {
    const fullPath = prefix ? `${prefix}.${key}` : key;
    if (typeof value === 'object' && value !== null) {
      return getAllKeys(value as TranslationObject, fullPath);
    }
    return [fullPath];
  });
}

function loadJson(filePath: string): TranslationObject {
  const content = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(content);
}

function getLocaleFiles(): string[] {
  return fs
    .readdirSync(MESSAGES_DIR)
    .filter((file) => file.endsWith('.json'))
    .map((file) => file.replace('.json', ''));
}

function main() {
  const locales = getLocaleFiles();
  console.log(`Found locales: ${locales.join(', ')}\n`);

  const sourceFile = path.join(MESSAGES_DIR, `${SOURCE_LOCALE}.json`);
  if (!fs.existsSync(sourceFile)) {
    console.error(`Source file not found: ${sourceFile}`);
    process.exit(1);
  }

  const sourceTranslations = loadJson(sourceFile);
  const sourceKeys = new Set(getAllKeys(sourceTranslations));
  console.log(`Source (${SOURCE_LOCALE}) has ${sourceKeys.size} keys\n`);

  let hasErrors = false;
  const warnings: string[] = [];

  for (const locale of locales) {
    if (locale === SOURCE_LOCALE) continue;

    const localeFile = path.join(MESSAGES_DIR, `${locale}.json`);
    const localeTranslations = loadJson(localeFile);
    const localeKeys = new Set(getAllKeys(localeTranslations));

    const missingKeys = [...sourceKeys].filter((key) => !localeKeys.has(key));
    const extraKeys = [...localeKeys].filter((key) => !sourceKeys.has(key));

    console.log(`\n=== ${locale.toUpperCase()} ===`);
    console.log(`Total keys: ${localeKeys.size}`);

    if (missingKeys.length > 0) {
      hasErrors = true;
      console.log(`\n❌ Missing keys (${missingKeys.length}):`);
      missingKeys.forEach((key) => console.log(`   - ${key}`));
    } else {
      console.log('✅ All source keys present');
    }

    if (extraKeys.length > 0) {
      warnings.push(`${locale}: ${extraKeys.length} extra keys`);
      console.log(`\n⚠️  Extra keys (${extraKeys.length}):`);
      extraKeys.forEach((key) => console.log(`   - ${key}`));
    }
  }

  console.log('\n' + '='.repeat(50));

  if (warnings.length > 0) {
    console.log('\n⚠️  Warnings:');
    warnings.forEach((w) => console.log(`   - ${w}`));
  }

  if (hasErrors) {
    console.log('\n❌ Validation FAILED - missing translations found');
    process.exit(1);
  } else {
    console.log('\n✅ Translation keys validated successfully!');
    process.exit(0);
  }
}

main();
