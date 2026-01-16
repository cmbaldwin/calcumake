# Automated Translation System

## Overview

CalcuMake uses an automated translation system powered by OpenRouter API (Google Gemini Flash 1.5) to maintain translations across 7 languages without manual translation work.

**Key Principle**: Only maintain English files (`en.yml` and `devise.en.yml`). All other locales are automatically translated during deployment.

## Supported Languages

1. **English (en)** - Master locale (manually maintained)
2. **Japanese (ja)** - Auto-translated
3. **Spanish (es)** - Auto-translated
4. **French (fr)** - Auto-translated
5. **Arabic (ar)** - Auto-translated
6. **Hindi (hi)** - Auto-translated
7. **Simplified Chinese (zh-CN)** - Auto-translated

## Architecture

### Components

1. **`bin/translate-locales`** - Core translation engine with OpenRouter API
2. **`bin/sync-translations`** - Intelligent wrapper (auto-detects API key)
3. **`.kamal/hooks/pre-build`** - Deployment hook integration
4. **`tmp/translation_cache/`** - Translation cache directory (gitignored)

### Translation Model

**Model**: `google/gemini-flash-1.5-8b`

**Why Gemini Flash?**

- Extremely fast response times (~500ms per batch)
- Very cost-effective (~$0.00001875 per 1M tokens)
- Excellent at structured translation tasks
- Handles technical terminology well
- Full translation of 1265+ keys × 6 languages ≈ $0.10 total

## Workflows

### Development Workflow (Local)

**Without API Key** (Default for developers):

```bash
# 1. Add new translation keys to English master
vim config/locales/en.yml

# 2. Sync with English placeholders
bin/sync-translations

# 3. Test
bin/rails test
```

**With API Key** (Optional for testing):

```bash
# 1. Set API key
export OPENROUTER_TRANSLATION_KEY='your-key-here'

# 2. Add new keys
vim config/locales/en.yml

# 3. Auto-translate
bin/sync-translations

# 4. Test
bin/rails test
```

### Production Workflow (Deployment)

Fully automated via Kamal pre-build hook:

```bash
# 1. Developer adds keys to en.yml
vim config/locales/en.yml

# 2. Commit and push
git add config/locales/en.yml
git commit -m "Add new translation keys"
git push

# 3. Deploy (translations happen automatically)
bin/kamal deploy
```

**Pre-build hook behavior:**

By default, the pre-build hook only translates **NEW/MISSING keys** (uses cache):

1. Loads OPENROUTER_TRANSLATION_KEY from Kamal secrets
2. Skips `force-retranslate` (cache preserved)
3. Runs `bin/sync-translations` - only translates missing keys
4. Stages translation changes
5. Runs tests
6. Auto-commits if tests pass
7. Builds and deploys

**Force retranslation** (when needed):

To force retranslation of ALL keys (clears cache):

```bash
# Deploy with force retranslate flag
kamal deploy -e FORCE_RETRANSLATE=1
```

This is useful when:

- Translation quality needs improvement
- You want to update all translations to a new model/version
- English placeholder values slipped through and need fixing

**Pre-build hook sequence (with FORCE_RETRANSLATE=1):**

1. Loads OPENROUTER_TRANSLATION_KEY from Kamal secrets
2. Runs `bin/force-retranslate` - clears cache for English placeholders
3. Runs `bin/sync-translations` - retranslates all cleared keys
4. Stages translation changes
5. Runs tests
6. Auto-commits if tests pass
7. Builds and deploys

## Scripts

### `bin/sync-translations`

Intelligent wrapper that detects API key availability:

**With API key**: Calls `bin/translate-locales` for automated translation
**Without API key**: Falls back to English placeholder sync

```bash
# Usage
bin/sync-translations

# Output (without API key):
# 📝 No API key detected - syncing with English placeholders
#    Set OPENROUTER_TRANSLATION_KEY for automated translations

# Output (with API key):
# 🤖 API key detected - using automated translation
# [executes bin/translate-locales]
```

### `bin/force-retranslate`

Clears translation cache for keys with English placeholder values:

**Purpose:**

- Detects keys in non-English locales that contain English text
- Removes these keys from the translation cache
- Allows `bin/translate-locales` to retranslate them

**Usage:**

```bash
# Clear cache for English placeholders
bin/force-retranslate

# Then run translation
bin/sync-translations
```

**When to use:**

- English placeholder values slipped into translated files
- You want to force retranslation of specific keys
- Translation quality needs improvement

**Output:**

```
================================================================================
Force Re-Translation Tool
================================================================================

📖 Loaded 1330 English keys

🌍 Processing ja...
   📝 Found 12 keys with English values
   🗑️  Removed 12 cached translations
   📋 Sample keys to re-translate:
      - print_pricing.job_name: "Job Name"
      - invoices.invoice_number: "Invoice Number"
      ... and 10 more

🌍 Processing es...
   ✅ No English values found (1330 keys)

================================================================================
✨ Cache cleared for English values!
================================================================================

💡 Next steps:
   1. Run 'bin/sync-translations' with OPENROUTER_TRANSLATION_KEY set
   2. Or run 'bin/translate-locales' directly
   3. Keys with English values will be re-translated
```

**Note:** This script is automatically run during `kamal deploy` when `FORCE_RETRANSLATE=1` is set.

### `bin/translate-locales`

Direct OpenRouter API integration:

**Features:**

- Loads `en.yml` + `devise.en.yml` as master sources
- Compares against all target locale files
- Batches translations (50 keys per request)
- Caches results in `tmp/translation_cache/{locale}.json`
- Validates interpolation variables
- Resumes from cache if interrupted

**Usage:**

```bash
# Requires API key
export OPENROUTER_TRANSLATION_KEY='your-key'
bin/translate-locales
```

**Output:**

```
================================================================================
CalcuMake Automated Translation System
Using OpenRouter API with Google Gemini Flash 1.5
================================================================================

📖 Loaded 1265 keys from en.yml
📖 Loaded 65 keys from devise.en.yml
📊 Total: 1330 keys to manage

🌍 Processing ja (Japanese)...
   📝 Found 44 missing keys
   📦 Batch 1/1 (44 keys)
   🌐 Translating 44 keys to Japanese...
   ✅ Translated 44 keys (0 from cache)
   💾 Updated ja.yml

🌍 Processing es (Spanish)...
   📝 Found 45 missing keys
   📦 Batch 1/1 (45 keys)
   🌐 Translating 45 keys to Spanish...
   ✅ Translated 45 keys (0 from cache)
   💾 Updated es.yml

...

================================================================================
✨ Translation Complete!
================================================================================
📊 Statistics:
   • Languages processed: 6
   • Total translations: 264
   • API calls made: 6
   • Cache directory: tmp/translation_cache

💡 Next steps:
   1. Review the updated locale files
   2. Run 'bin/rails test' to ensure nothing broke
   3. Commit the changes if everything looks good
```

## Translation Quality

### Validation Features

1. **Interpolation Variable Preservation**

   - Ensures `%{name}`, `%{count}`, etc. are preserved exactly
   - Validates before writing to locale files
   - Falls back to English if validation fails

2. **HTML/ERB Tag Preservation**

   - Maintains `%{}` tags
   - Preserves HTML structure
   - Keeps formatting intact

3. **Technical Terminology**
   - Context-aware for 3D printing terms
   - Preserves technical accuracy (filament, STL, G-code, etc.)
   - Professional UI language

### Translation Prompt

The system uses a carefully crafted prompt:

```
You are a professional translator for a 3D printing management web application called CalcuMake.

Translate the following English UI strings to {language}.

CRITICAL RULES:
1. Preserve all interpolation variables EXACTLY as shown (e.g., %{name}, %{count}, etc.)
2. Preserve HTML tags if present
3. Keep technical terms accurate (e.g., "filament", "printer", "STL file")
4. Use natural, professional language for UI elements
5. For currency symbols, keep %{} tags intact
6. Return ONLY the translations in the same key: value format, nothing else
```

## Caching System

### Cache Structure

```
tmp/translation_cache/
├── ja.json      # Japanese translations
├── es.json      # Spanish translations
├── fr.json      # French translations
├── ar.json      # Arabic translations
├── hi.json      # Hindi translations
└── zh-CN.json   # Simplified Chinese translations
```

### Cache Format

```json
{
  "users.sign_in.title": "ログイン",
  "users.sign_in.email": "メールアドレス",
  "users.sign_in.password": "パスワード",
  ...
}
```

### Cache Benefits

1. **Resume capability**: Can restart translation if interrupted
2. **Avoid re-translation**: Already translated keys skip API calls
3. **Faster iteration**: Only new keys trigger API requests
4. **Cost savings**: Cached keys don't incur API costs

### Cache Management

```bash
# Clear cache for a specific language
rm tmp/translation_cache/ja.json

# Clear all caches
rm -rf tmp/translation_cache/

# Force re-translation (cache automatically recreated)
rm tmp/translation_cache/*.json && bin/translate-locales
```

## Configuration

### Environment Variables

**Development** (`.env.local`):

```bash
OPENROUTER_TRANSLATION_KEY=sk-or-v1-xxxxx
```

**Production** (Kamal secrets):

```ruby
# .kamal/secrets
OPENROUTER_TRANSLATION_KEY=$(kamal secrets extract CALCUMAKE_OPENROUTER_TRANSLATION_KEY ${SECRETS})
```

**Deployment** (`config/deploy.yml`):

```yaml
env:
  secret:
    - OPENROUTER_TRANSLATION_KEY
```

### API Key Setup

1. **Get API Key**: https://openrouter.ai/keys
2. **Store in 1Password**: Field name `CALCUMAKE_OPENROUTER_TRANSLATION_KEY`
3. **Extract in secrets**: Already configured in `.kamal/secrets`

## Cost Analysis

### Typical Translation Costs

**Full translation** (1265 keys × 6 languages = 7,590 translations):

- Input tokens: ~50,000 (prompts + keys)
- Output tokens: ~40,000 (translations)
- **Total cost**: ~$0.08 - $0.10

**Incremental updates** (10 new keys × 6 languages = 60 translations):

- Input tokens: ~4,000
- Output tokens: ~3,000
- **Total cost**: ~$0.006 - $0.01

**Monthly estimate** (assuming 50 keys added per month):

- **Total cost**: ~$0.05 per month

### Cost Optimization

1. **Caching**: Avoid re-translating existing keys
2. **Batching**: 50 keys per request minimizes overhead
3. **Efficient model**: Gemini Flash 1.5 is 10x cheaper than GPT-4
4. **Smart fallback**: English placeholders in development save API calls

## Troubleshooting

### Translation Not Running

**Problem**: Deployment doesn't translate

**Solutions**:

1. Check API key is in 1Password: `CALCUMAKE_OPENROUTER_TRANSLATION_KEY`
2. Verify secrets extraction in `.kamal/secrets`
3. Confirm env variable in `config/deploy.yml`
4. Check pre-build hook output during deployment

### Validation Failures

**Problem**: Variables not preserved

**Symptoms**:

```
⚠️  Variable mismatch in users.welcome:
    Original: %{name}
    Translated: {nombre}
```

**Solution**: Falls back to English automatically, but you can:

1. Check cache file for incorrect translation
2. Delete cache file and re-translate
3. Manually fix in locale file if needed

### API Errors

**Problem**: API request failed

**Common causes**:

1. Invalid API key
2. Rate limiting (wait 1 second between batches)
3. Network issues

**Debug**:

```bash
# Test API key manually
export OPENROUTER_TRANSLATION_KEY='your-key'
bin/translate-locales
```

### Structural Warnings

**Problem**: "Cannot set key - target is not a hash"

**Example**:

```
⚠️  Cannot set print_pricing.filament_types.pla - target is not a hash
```

**Cause**: Locale file has `filament_types: "some string"` instead of hash

**Solution**: Fix structure in target locale file manually

## Best Practices

### 1. Only Edit English Files

❌ **Don't**:

```bash
# Editing translated files directly
vim config/locales/ja.yml  # BAD!
```

✅ **Do**:

```bash
# Only edit English master
vim config/locales/en.yml  # GOOD!
vim config/locales/devise.en.yml  # GOOD!
```

### 2. Use Descriptive Keys

❌ **Don't**:

```yaml
users:
  msg1: "Welcome"
  msg2: "Click here"
```

✅ **Do**:

```yaml
users:
  welcome_message: "Welcome to CalcuMake"
  click_to_continue: "Click here to continue"
```

### 3. Test After Translation

Always run tests after syncing translations:

```bash
bin/sync-translations
bin/rails test
```

### 4. Review Translations

While automated translation is high quality, periodically review:

```bash
# Check a specific language
git diff config/locales/ja.yml

# Review technical terms
grep "filament\|STL\|G-code" config/locales/ja.yml
```

### 5. Leverage Caching

Don't delete cache unless necessary:

```bash
# Cache speeds up subsequent runs
bin/translate-locales  # First run: hits API
bin/translate-locales  # Second run: uses cache (instant)
```

## Future Enhancements

Potential improvements (not currently implemented):

- [ ] Translation memory across projects
- [ ] Quality scoring for translations
- [ ] A/B testing different translation models
- [ ] Manual translation override system
- [ ] Translation review workflow
- [ ] Terminology glossary management
- [ ] Parallel translation for faster processing
- [ ] Translation diff viewer

## References

- **OpenRouter API Docs**: https://openrouter.ai/docs
- **Gemini Flash Model**: https://ai.google.dev/gemini-api/docs/models/gemini
- **Kamal Hooks**: https://kamal-deploy.org/docs/hooks/
- **Rails I18n Guide**: https://guides.rubyonrails.org/i18n.html
