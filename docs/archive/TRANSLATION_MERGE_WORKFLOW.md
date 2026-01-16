# Translation Merge Workflow

## Problem

Merging Git branches that both modify locale YAML files often results in conflicts. Standard text-based Git merge doesn't understand YAML structure, leading to:
- Invalid YAML syntax after merge
- Lost translation keys
- Broken indentation
- Manual conflict resolution errors

## Solution

Use semantic YAML merging with Ruby's built-in YAML parser.

## Tools

### 1. `bin/merge-locale-yml` (Project Script)

Located in `bin/merge-locale-yml`, this script performs deep merging of YAML locale files:

```bash
bin/merge-locale-yml <base_file> <feature_file> <output_file>
```

**Example:**
```bash
bin/merge-locale-yml config/locales/en.yml /tmp/feature_en.yml config/locales/en.yml
```

**Features:**
- Deep merge preserves all keys from both files
- Feature keys override base keys (last writer wins)
- Validates output YAML syntax
- Clear error messages with line/column numbers

### 2. VS Code Extensions (Recommended)

Install these VS Code extensions for better YAML editing:

#### **YAML by Red Hat** (`redhat.vscode-yaml`)
- Real-time syntax validation
- Auto-formatting
- Schema validation
- Hover documentation

#### **i18n Ally** (`lokalise.i18n-ally`)
- Inline translation previews
- Missing translation detection
- Translation key navigation
- Multi-locale editing

Install via VS Code:
```bash
code --install-extension redhat.vscode-yaml
code --install-extension lokalise.i18n-ally
```

### 3. Rails i18n-tasks Gem (Advanced)

For larger projects, consider the `i18n-tasks` gem:

```ruby
# Gemfile (development group)
gem 'i18n-tasks', '~> 1.0'
```

Features:
- Find missing/unused translations
- Normalize locale files
- Machine translation integration
- Google Sheets sync

## Workflow for Merging PRs with Translation Conflicts

### Step 1: Identify Conflicts

```bash
git merge feature-branch
# CONFLICT in config/locales/*.yml
```

### Step 2: Extract Both Versions

```bash
# For each conflicting locale file (e.g., en.yml):
git show HEAD:config/locales/en.yml > /tmp/base_en.yml
git show feature-branch:config/locales/en.yml > /tmp/feature_en.yml
```

### Step 3: Merge with Tool

```bash
bin/merge-locale-yml /tmp/base_en.yml /tmp/feature_en.yml config/locales/en.yml
```

### Step 4: Verify All Locales

```bash
# Verify all 7 language files
for lang in en ja zh-CN hi es fr ar; do
  echo "Checking $lang.yml..."
  ruby -ryaml -e "YAML.load_file('config/locales/$lang.yml'); puts '✓ Valid'"
done
```

### Step 5: Test in Rails

```bash
# Load Rails console to verify I18n loads correctly
bin/rails console
> I18n.t('subscriptions.title')
# Should return translated string without errors
```

## Batch Merge Script

For merging all locale files at once:

```bash
#!/bin/bash
# merge-all-locales.sh

FEATURE_BRANCH=$1

for lang in en ja zh-CN hi es fr ar; do
  echo "Merging $lang.yml..."

  git show HEAD:config/locales/$lang.yml > /tmp/base_$lang.yml
  git show $FEATURE_BRANCH:config/locales/$lang.yml > /tmp/feature_$lang.yml

  bin/merge-locale-yml /tmp/base_$lang.yml /tmp/feature_$lang.yml config/locales/$lang.yml

  # Verify
  ruby -ryaml -e "YAML.load_file('config/locales/$lang.yml'); puts '  ✓ Validated'"
done

echo "All locale files merged successfully!"
```

Usage:
```bash
chmod +x merge-all-locales.sh
./merge-all-locales.sh feature-branch-name
```

## Git Merge Strategy Configuration

Add to `.gitattributes` to use Ruby-based merge for YAML files:

```
# .gitattributes
config/locales/*.yml merge=yaml-merge
```

Configure Git to use the merge driver:

```bash
git config merge.yaml-merge.driver "bin/merge-locale-yml %O %A %B %A"
git config merge.yaml-merge.name "YAML deep merge driver"
```

This will automatically use `bin/merge-locale-yml` when Git detects conflicts in locale files.

## Best Practices

1. **Always validate after merge**: Run `ruby -ryaml -e "YAML.load_file('...')"`
2. **Test in development**: Start Rails server and check translations load
3. **Run I18n tests**: Ensure no `translation_missing` errors
4. **Keep locales in sync**: All 7 languages should have matching key structure
5. **Use consistent formatting**: Let `to_yaml` handle formatting
6. **Review diffs carefully**: Check that no keys were lost in merge

## Common Issues

### Issue: "did not find expected key"
**Cause**: Indentation error or missing colon
**Fix**: Use `bin/merge-locale-yml` which preserves structure

### Issue: Duplicate keys after merge
**Cause**: Manual conflict resolution
**Fix**: Deep merge automatically handles duplicates (last writer wins)

### Issue: Lost translation keys
**Cause**: Git chose wrong side during conflict
**Fix**: Semantic merge preserves all keys from both files

## Testing Translation Completeness

```ruby
# test/i18n_test.rb
require "test_helper"

class I18nTest < ActiveSupport::TestCase
  test "all locales have same keys" do
    base_keys = flat_keys('en')

    %w[ja zh-CN hi es fr ar].each do |locale|
      locale_keys = flat_keys(locale)
      missing = base_keys - locale_keys
      extra = locale_keys - base_keys

      assert_empty missing, "#{locale} missing keys: #{missing.join(', ')}"
      assert_empty extra, "#{locale} has extra keys: #{extra.join(', ')}"
    end
  end

  private

  def flat_keys(locale)
    I18n.backend.send(:translations)[locale.to_sym].flat_map { |k, v| extract_keys(k, v) }
  end

  def extract_keys(key, value, prefix = '')
    full_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"

    if value.is_a?(Hash)
      value.flat_map { |k, v| extract_keys(k, v, full_key) }
    else
      [full_key]
    end
  end
end
```

## References

- [Ruby YAML Psych Documentation](https://ruby-doc.org/stdlib-3.0.0/libdoc/psych/rdoc/Psych.html)
- [i18n-tasks Gem](https://github.com/glebm/i18n-tasks)
- [VS Code YAML Extension](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)
- [i18n Ally Extension](https://marketplace.visualstudio.com/items?itemName=lokalise.i18n-ally)
