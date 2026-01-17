'use client';

import { useState, useRef, useEffect } from 'react';
import Image from 'next/image';

export interface CookingStyleOption {
  value: string;
  label: string;
}

interface CookingStyleSelectProps {
  value: string;
  onChange: (value: string) => void;
  options: CookingStyleOption[];
  placeholder?: string;
  className?: string;
}

function getFlagUrl(code: string): string {
  if (code === 'any' || code === 'international') {
    return 'https://flagcdn.com/w40/un.png';
  }
  return `https://flagcdn.com/w40/${code.toLowerCase()}.png`;
}

export function CookingStyleSelect({
  value,
  onChange,
  options,
  placeholder = 'Select...',
  className = '',
}: CookingStyleSelectProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const containerRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  const selectedOption = options.find((opt) => opt.value === value);

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
        setSearch('');
      }
    }

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Focus search input when dropdown opens
  useEffect(() => {
    if (isOpen && searchInputRef.current) {
      searchInputRef.current.focus();
    }
  }, [isOpen]);

  const filteredOptions = search
    ? options.filter((opt) =>
        opt.label.toLowerCase().includes(search.toLowerCase())
      )
    : options;

  const handleSelect = (optionValue: string) => {
    onChange(optionValue);
    setIsOpen(false);
    setSearch('');
  };

  return (
    <div ref={containerRef} className={`relative ${className}`}>
      {/* Selected value button */}
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] flex items-center justify-between gap-2 text-sm"
      >
        <span className="flex items-center gap-2 min-w-0">
          {selectedOption && (
            <>
              <Image
                src={getFlagUrl(selectedOption.value)}
                alt=""
                width={20}
                height={15}
                className="rounded-sm flex-shrink-0"
                unoptimized
              />
              <span className="truncate">{selectedOption.label}</span>
            </>
          )}
          {!selectedOption && (
            <span className="text-[var(--text-secondary)]">{placeholder}</span>
          )}
        </span>
        <svg
          className={`w-4 h-4 text-[var(--text-secondary)] transition-transform flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {/* Dropdown */}
      {isOpen && (
        <div className="absolute z-50 mt-1 w-full bg-[var(--surface)] border border-[var(--border)] rounded-lg shadow-lg overflow-hidden">
          {/* Search input */}
          <div className="p-2 border-b border-[var(--border)]">
            <input
              ref={searchInputRef}
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search..."
              className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-md text-sm focus:outline-none focus:border-[var(--primary)]"
            />
          </div>

          {/* Options list */}
          <div className="max-h-60 overflow-y-auto">
            {filteredOptions.length === 0 ? (
              <div className="px-3 py-2 text-sm text-[var(--text-secondary)]">
                No results found
              </div>
            ) : (
              filteredOptions.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => handleSelect(option.value)}
                  className={`w-full px-3 py-2 flex items-center gap-2 text-sm hover:bg-[var(--highlight-bg)] transition-colors text-left ${
                    option.value === value ? 'bg-[var(--primary-light)]/20' : ''
                  }`}
                >
                  <Image
                    src={getFlagUrl(option.value)}
                    alt=""
                    width={20}
                    height={15}
                    className="rounded-sm flex-shrink-0"
                    unoptimized
                  />
                  <span className="truncate">{option.label}</span>
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// Shared cooking style options for use across the app
export const COOKING_STYLE_OPTIONS: CookingStyleOption[] = [
  { value: 'international', label: 'International' },
  { value: 'AF', label: 'Afghan' },
  { value: 'AL', label: 'Albanian' },
  { value: 'DZ', label: 'Algerian' },
  { value: 'AD', label: 'Andorran' },
  { value: 'AO', label: 'Angolan' },
  { value: 'AG', label: 'Antiguan' },
  { value: 'AR', label: 'Argentine' },
  { value: 'AM', label: 'Armenian' },
  { value: 'AU', label: 'Australian' },
  { value: 'AT', label: 'Austrian' },
  { value: 'AZ', label: 'Azerbaijani' },
  { value: 'BS', label: 'Bahamian' },
  { value: 'BH', label: 'Bahraini' },
  { value: 'BD', label: 'Bangladeshi' },
  { value: 'BB', label: 'Barbadian' },
  { value: 'BY', label: 'Belarusian' },
  { value: 'BE', label: 'Belgian' },
  { value: 'BZ', label: 'Belizean' },
  { value: 'BJ', label: 'Beninese' },
  { value: 'BT', label: 'Bhutanese' },
  { value: 'BO', label: 'Bolivian' },
  { value: 'BA', label: 'Bosnian' },
  { value: 'BW', label: 'Botswanan' },
  { value: 'BR', label: 'Brazilian' },
  { value: 'BN', label: 'Bruneian' },
  { value: 'BG', label: 'Bulgarian' },
  { value: 'BF', label: 'Burkinabe' },
  { value: 'BI', label: 'Burundian' },
  { value: 'KH', label: 'Cambodian' },
  { value: 'CM', label: 'Cameroonian' },
  { value: 'CA', label: 'Canadian' },
  { value: 'CV', label: 'Cape Verdean' },
  { value: 'CF', label: 'Central African' },
  { value: 'TD', label: 'Chadian' },
  { value: 'CL', label: 'Chilean' },
  { value: 'CN', label: 'Chinese' },
  { value: 'CO', label: 'Colombian' },
  { value: 'KM', label: 'Comorian' },
  { value: 'CG', label: 'Congolese' },
  { value: 'CR', label: 'Costa Rican' },
  { value: 'HR', label: 'Croatian' },
  { value: 'CU', label: 'Cuban' },
  { value: 'CY', label: 'Cypriot' },
  { value: 'CZ', label: 'Czech' },
  { value: 'DK', label: 'Danish' },
  { value: 'DJ', label: 'Djiboutian' },
  { value: 'DM', label: 'Dominican' },
  { value: 'DO', label: 'Dominican (DR)' },
  { value: 'EC', label: 'Ecuadorian' },
  { value: 'EG', label: 'Egyptian' },
  { value: 'SV', label: 'Salvadoran' },
  { value: 'GQ', label: 'Equatorial Guinean' },
  { value: 'ER', label: 'Eritrean' },
  { value: 'EE', label: 'Estonian' },
  { value: 'SZ', label: 'Eswatini' },
  { value: 'ET', label: 'Ethiopian' },
  { value: 'FJ', label: 'Fijian' },
  { value: 'FI', label: 'Finnish' },
  { value: 'FR', label: 'French' },
  { value: 'GA', label: 'Gabonese' },
  { value: 'GM', label: 'Gambian' },
  { value: 'GE', label: 'Georgian' },
  { value: 'DE', label: 'German' },
  { value: 'GH', label: 'Ghanaian' },
  { value: 'GR', label: 'Greek' },
  { value: 'GD', label: 'Grenadian' },
  { value: 'GT', label: 'Guatemalan' },
  { value: 'GN', label: 'Guinean' },
  { value: 'GW', label: 'Guinea-Bissauan' },
  { value: 'GY', label: 'Guyanese' },
  { value: 'HT', label: 'Haitian' },
  { value: 'HN', label: 'Honduran' },
  { value: 'HU', label: 'Hungarian' },
  { value: 'IS', label: 'Icelandic' },
  { value: 'IN', label: 'Indian' },
  { value: 'ID', label: 'Indonesian' },
  { value: 'IR', label: 'Iranian' },
  { value: 'IQ', label: 'Iraqi' },
  { value: 'IE', label: 'Irish' },
  { value: 'IL', label: 'Israeli' },
  { value: 'IT', label: 'Italian' },
  { value: 'CI', label: 'Ivorian' },
  { value: 'JM', label: 'Jamaican' },
  { value: 'JP', label: 'Japanese' },
  { value: 'JO', label: 'Jordanian' },
  { value: 'KZ', label: 'Kazakh' },
  { value: 'KE', label: 'Kenyan' },
  { value: 'KI', label: 'Kiribati' },
  { value: 'KW', label: 'Kuwaiti' },
  { value: 'KG', label: 'Kyrgyz' },
  { value: 'LA', label: 'Laotian' },
  { value: 'LV', label: 'Latvian' },
  { value: 'LB', label: 'Lebanese' },
  { value: 'LS', label: 'Lesotho' },
  { value: 'LR', label: 'Liberian' },
  { value: 'LY', label: 'Libyan' },
  { value: 'LI', label: 'Liechtensteiner' },
  { value: 'LT', label: 'Lithuanian' },
  { value: 'LU', label: 'Luxembourgish' },
  { value: 'MG', label: 'Malagasy' },
  { value: 'MW', label: 'Malawian' },
  { value: 'MY', label: 'Malaysian' },
  { value: 'MV', label: 'Maldivian' },
  { value: 'ML', label: 'Malian' },
  { value: 'MT', label: 'Maltese' },
  { value: 'MH', label: 'Marshallese' },
  { value: 'MR', label: 'Mauritanian' },
  { value: 'MU', label: 'Mauritian' },
  { value: 'MX', label: 'Mexican' },
  { value: 'FM', label: 'Micronesian' },
  { value: 'MD', label: 'Moldovan' },
  { value: 'MC', label: 'Monacan' },
  { value: 'MN', label: 'Mongolian' },
  { value: 'ME', label: 'Montenegrin' },
  { value: 'MA', label: 'Moroccan' },
  { value: 'MZ', label: 'Mozambican' },
  { value: 'MM', label: 'Myanmar' },
  { value: 'NA', label: 'Namibian' },
  { value: 'NR', label: 'Nauruan' },
  { value: 'NP', label: 'Nepali' },
  { value: 'NL', label: 'Dutch' },
  { value: 'NZ', label: 'New Zealand' },
  { value: 'NI', label: 'Nicaraguan' },
  { value: 'NE', label: 'Nigerien' },
  { value: 'NG', label: 'Nigerian' },
  { value: 'KP', label: 'North Korean' },
  { value: 'MK', label: 'North Macedonian' },
  { value: 'NO', label: 'Norwegian' },
  { value: 'OM', label: 'Omani' },
  { value: 'PK', label: 'Pakistani' },
  { value: 'PW', label: 'Palauan' },
  { value: 'PS', label: 'Palestinian' },
  { value: 'PA', label: 'Panamanian' },
  { value: 'PG', label: 'Papua New Guinean' },
  { value: 'PY', label: 'Paraguayan' },
  { value: 'PE', label: 'Peruvian' },
  { value: 'PH', label: 'Filipino' },
  { value: 'PL', label: 'Polish' },
  { value: 'PT', label: 'Portuguese' },
  { value: 'QA', label: 'Qatari' },
  { value: 'RO', label: 'Romanian' },
  { value: 'RU', label: 'Russian' },
  { value: 'RW', label: 'Rwandan' },
  { value: 'KN', label: 'Kittitian' },
  { value: 'LC', label: 'Saint Lucian' },
  { value: 'VC', label: 'Vincentian' },
  { value: 'WS', label: 'Samoan' },
  { value: 'SM', label: 'Sammarinese' },
  { value: 'ST', label: 'Sao Tomean' },
  { value: 'SA', label: 'Saudi' },
  { value: 'SN', label: 'Senegalese' },
  { value: 'RS', label: 'Serbian' },
  { value: 'SC', label: 'Seychellois' },
  { value: 'SL', label: 'Sierra Leonean' },
  { value: 'SG', label: 'Singaporean' },
  { value: 'SK', label: 'Slovak' },
  { value: 'SI', label: 'Slovenian' },
  { value: 'SB', label: 'Solomon Islander' },
  { value: 'SO', label: 'Somali' },
  { value: 'ZA', label: 'South African' },
  { value: 'KR', label: 'Korean' },
  { value: 'SS', label: 'South Sudanese' },
  { value: 'ES', label: 'Spanish' },
  { value: 'LK', label: 'Sri Lankan' },
  { value: 'SD', label: 'Sudanese' },
  { value: 'SR', label: 'Surinamese' },
  { value: 'SE', label: 'Swedish' },
  { value: 'CH', label: 'Swiss' },
  { value: 'SY', label: 'Syrian' },
  { value: 'TW', label: 'Taiwanese' },
  { value: 'TJ', label: 'Tajik' },
  { value: 'TZ', label: 'Tanzanian' },
  { value: 'TH', label: 'Thai' },
  { value: 'TL', label: 'Timorese' },
  { value: 'TG', label: 'Togolese' },
  { value: 'TO', label: 'Tongan' },
  { value: 'TT', label: 'Trinidadian' },
  { value: 'TN', label: 'Tunisian' },
  { value: 'TR', label: 'Turkish' },
  { value: 'TM', label: 'Turkmen' },
  { value: 'TV', label: 'Tuvaluan' },
  { value: 'UG', label: 'Ugandan' },
  { value: 'UA', label: 'Ukrainian' },
  { value: 'AE', label: 'Emirati' },
  { value: 'GB', label: 'British' },
  { value: 'US', label: 'American' },
  { value: 'UY', label: 'Uruguayan' },
  { value: 'UZ', label: 'Uzbek' },
  { value: 'VU', label: 'Vanuatuan' },
  { value: 'VA', label: 'Vatican' },
  { value: 'VE', label: 'Venezuelan' },
  { value: 'VN', label: 'Vietnamese' },
  { value: 'YE', label: 'Yemeni' },
  { value: 'ZM', label: 'Zambian' },
  { value: 'ZW', label: 'Zimbabwean' },
];

// Filter options include "All Styles" at the top
export const COOKING_STYLE_FILTER_OPTIONS: CookingStyleOption[] = [
  { value: 'any', label: 'All Styles' },
  ...COOKING_STYLE_OPTIONS,
];
