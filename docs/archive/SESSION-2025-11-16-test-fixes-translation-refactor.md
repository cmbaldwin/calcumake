# Session 2025-11-16: Test Fixes & Translation Refactoring

## Overview
Fixed failing tests and refactored translation system to use split domain files instead of monolithic YAML.

## Test Fixes (30 → 24 failures/errors)

### Fixed Issues
1. **Missing Translation Keys** - Added comprehensive translations to en.yml:
   - `subscriptions.features.*` (filaments, invoices, unlimited_invoices)
   - `subscriptions.upgrade_successful` with `%{plan}` parameter
   - `subscriptions.verification_error`
   - `invoices.made_with_calcumake`
   - Complete `gdpr.data_export.items.*` structure
   - Complete `gdpr.data_deletion.items.*` structure
   - `gdpr.tos_sections.user_accounts`
   - `gdpr.cookie_sections.how_we_use`
   - `gdpr.privacy_policy_title`

2. **Landing Page Structured Data** - Fixed ERB syntax error in `app/views/pages/landing.html.erb:11`
   - Changed `< %= @structured_data.to_json.html_safe % >` to `<%= @structured_data.to_json.html_safe %>`

3. **Printer Controller Tests** - Fixed missing required fields in test data
   - Added `daily_usage_hours: 8` and `repair_cost_percentage: 5.0` to printer creation tests

4. **Invoice Logo Asset** - Ensured CalcuMake logo displays correctly
   - Removed conditional check as per user requirement (logo must always be present)
   - Asset properly loads from `app/assets/images/calcumake.png`

5. **Landing Page Pricing Test** - Updated expectations to match actual pricing
   - Changed from `$0.99/$9.99` to `¥150/¥1,500` (Japanese Yen)

6. **Devise OAuth Translations** - Added missing `devise.shared` keys
   - `oauth_signin_options`, `alternative_signin_method`, `or_sign_in_with_email`
   - `sign_in_with_provider`, `sign_in_with_provider_aria`

### Remaining Issues (24 total)
- 17 failures, 7 errors
- Related to modal validation patterns, calculation precision, user consent controllers

## Translation System Refactoring

### Problem Identified
- Monolithic `en.yml` file was 1,365 lines (60KB)
- Prone to YAML corruption from sed/awk edits
- Difficult to navigate and maintain
- Created 6 backup files (.bak, .bak2, etc.) from failed sed operations

### Solution Implemented: Option 1 Architecture
**Split English source, combined other locales**

#### New Structure
```
config/locales/
├── en/                          # Split by domain (manually maintained)
│   ├── activerecord.yml         # 3.9KB - Model validations & errors
│   ├── navigation.yml           # 1.9KB - Nav, actions, flash, common
│   ├── print_pricings.yml       # 9.2KB - Print pricing features
│   ├── printers.yml             # 2.6KB - Printer management
│   ├── invoices.yml             # 2.9KB - Invoice features
│   ├── filaments.yml            # 2.8KB - Filament management
│   ├── clients.yml              # 2.1KB - Client management
│   ├── profile.yml              # 4.0KB - User profile & settings
│   ├── currency.yml             # 198B - Currency & energy
│   ├── application.yml          # 300B - App-wide strings
│   ├── support.yml              # 2.2KB - Support page
│   ├── legal.yml                # 16KB - Legal pages (largest)
│   ├── landing.yml              # 7.3KB - Landing page & marketing
│   ├── subscriptions.yml        # 849B - Subscription features
│   └── gdpr.yml                 # 3.0KB - GDPR & privacy
├── devise.en.yml                # Devise authentication (manually maintained)
└── ja.yml, es.yml, fr.yml,      # Auto-generated (single combined files)
    ar.yml, hi.yml, zh-CN.yml
```

#### Benefits
✅ Easier to edit - Find translations faster in smaller files
✅ Less prone to YAML corruption - Smaller files = less risk
✅ Better organization - Logical grouping by feature domain
✅ Easier code reviews - Changes isolated to specific files
✅ Proper Rails convention - Standard pattern for large apps

#### Implementation Details

**Created `bin/split-translations`**
- One-time utility to intelligently split monolithic en.yml
- Groups keys by domain automatically
- Preserves YAML structure and nesting

**Updated `bin/translate-locales`**
- Added `load_master_translations()` function
- Auto-detects `en/` directory vs single `en.yml`
- Merges all `en/*.yml` files before translation
- Backward compatible - falls back if directory doesn't exist
- Uses `deep_merge!()` helper for proper hash merging

**Rails i18n Compatibility**
- Rails automatically loads all YAML files in `config/locales/**/*`
- Split files work seamlessly without configuration changes
- Verified with: `bin/rails runner` tests for key translations

### Files Modified
- `bin/translate-locales` - Added merging logic for split files
- `config/locales/en.yml` → `config/locales/en/*.yml` (15 files)
- `config/locales/devise.en.yml` - Added missing shared translations
- `CLAUDE.md` - Updated documentation with new structure
- All test files - Fixed missing parameters and assertions

### Commits
1. `f652ee6` - Refactor translation system with backup
2. `90aafc6` - Remove en.yml.old backup file

## Key Learnings

### YAML File Management
- **Never use sed/awk for YAML edits** - Too error-prone, creates corruption
- **Use Read → Edit tools instead** - Safer, validates syntax
- **Split large files proactively** - 60KB is too large, 16KB max is better
- **Test YAML validity** - `ruby -ryaml -e "YAML.load_file('file.yml')"` after edits

### Translation Best Practices
- Only maintain English source files manually
- Auto-generated translations easier to review as single files
- Domain-based splitting improves maintainability
- Rails i18n loads everything from `config/locales/**/*` automatically

### Test-Driven Development
- Fix tests incrementally, verify frequently
- Translation errors show up in tests immediately
- Missing keys fail fast - good for catching issues early

## Next Steps
- Continue fixing remaining 24 test failures/errors
- Monitor translation system with new split structure
- Consider documenting common YAML editing patterns
- Update translation workflow documentation

## Statistics
- **Test Results**: 30 → 24 failures/errors (6 tests fixed)
- **Files Split**: 1 monolithic file → 15 domain files
- **Size Reduction**: 60KB → max 16KB per file
- **Translations Added**: ~15 missing keys across multiple namespaces
- **Lines of Code**: ~400 lines added/modified across all changes
