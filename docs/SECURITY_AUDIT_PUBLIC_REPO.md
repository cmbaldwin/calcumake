# Security Audit: Making CalcuMake Repository Public

**Date**: 2026-01-22
**Status**: CRITICAL - Action Required Before Public Release
**Auditor**: Claude Security Audit

---

## Executive Summary

This repository **CANNOT** be made public in its current state. The git history contains multiple leaked credentials that would compromise the application's security. There are two options:

1. **Option A**: Clean git history using BFG Repo-Cleaner (complex, error-prone)
2. **Option B**: Create a fresh repository with sanitized initial commit (recommended)

---

## Critical Findings

### SEVERITY: CRITICAL (Must Fix)

| Finding | File | Risk Level | Impact |
|---------|------|------------|--------|
| Rails master.key committed | `config/master.key` | **CRITICAL** | Can decrypt all Rails credentials |
| Stripe test API keys | `docs/archive/STRIPE_SETUP.md` | **CRITICAL** | API access to Stripe test environment |
| 1Password account ID | `.kamal/secrets` | **HIGH** | Targeted vault attacks |
| AWS Account ID + ECR URL | `config/deploy.yml` | **HIGH** | Infrastructure enumeration |
| Production server IP | `config/deploy.yml` | **HIGH** | Direct server targeting |

### Detailed Findings

#### 1. Rails Master Key (CRITICAL)

**File**: `config/master.key`
**Status**: Tracked in git (should be ignored)
**Value Exposed**: `6e52d08e9897c3489f74472d4d359b66`
**First Commit**: `636aadb`

**Impact**: Anyone with this key can decrypt `config/credentials.yml.enc`, exposing ALL encrypted secrets.

**Immediate Action Required**:
1. Rotate the master key
2. Re-encrypt all credentials
3. Update 1Password with new key
4. Redeploy application

#### 2. Stripe Test API Keys (CRITICAL)

**File**: `docs/archive/STRIPE_SETUP.md` (lines 27-31)
**Values Exposed**:
```
pk_test_51R9yZSDkapT94HR1yMHHFqD5XvRLOwpbKNB1oEVNJ9aCJU8sUdqpyloanCK46tU5kHAPk4iF4D9n21IdFCXy37VS00Q8GwfuVe
sk_test_51R9yZSDkapT94HR19Qg4oYamzdP7sYrU9wmOgKsfVFMR7SpoR2MOK9mjzuZEz5TPgckkQ4q2MLWHM7E0uf7G3fL800ZbnHVKBC
```
**Account ID**: `acct_1R9yZSDkapT94HR1`
**Price IDs**: `price_1SStMeDkapT94HR1vGXLi0kx`, `price_1SStQYDkapT94HR1fFNyOa9a`

**Impact**: Access to Stripe test environment, ability to create charges, view customer data.

**Immediate Action Required**:
1. Roll (regenerate) test API keys in Stripe Dashboard
2. Update 1Password with new keys

#### 3. 1Password Account ID (HIGH)

**File**: `.kamal/secrets` (line 5)
**Value Exposed**: `CNCYFLWUMZHE7MBS5AAOOSTLTI`
**Vault Name**: `MOAB/Production`

**Impact**: Attackers can target this specific 1Password account. Combined with other information, increases risk of social engineering attacks.

**Note**: This file is in `.gitignore` but was committed before the ignore rule was added.

#### 4. AWS ECR Registry URL (HIGH)

**File**: `config/deploy.yml` (line 41)
**Values Exposed**:
```
AWS Account ID: 047719641231
ECR Registry: 047719641231.dkr.ecr.ap-southeast-2.amazonaws.com
Region: ap-southeast-2
```

**Impact**:
- AWS account can be targeted for enumeration attacks
- ECR registry URL reveals infrastructure details
- Combined with other information, aids in infrastructure mapping

#### 5. Production Server IP (HIGH)

**File**: `config/deploy.yml` (lines 14, 133)
**Value Exposed**: `5.223.51.74`

**Impact**: Direct targeting of production server for:
- Port scanning
- Service enumeration
- Brute force attacks
- DDoS targeting

---

## Option A: Clean Git History (NOT RECOMMENDED)

### Process

Use BFG Repo-Cleaner to remove sensitive files from all commits:

```bash
# Clone a fresh copy
git clone --mirror git@github.com:org/calcumake.git calcumake-mirror

# Remove sensitive files
java -jar bfg.jar --delete-files master.key calcumake-mirror
java -jar bfg.jar --delete-files STRIPE_SETUP.md calcumake-mirror

# Replace text patterns
java -jar bfg.jar --replace-text patterns.txt calcumake-mirror

# Clean up
cd calcumake-mirror
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push
git push --force
```

### Risks

1. **Incomplete cleaning** - Easy to miss files or patterns
2. **Broken history** - All commit hashes change, breaking references
3. **Coordination required** - All developers must re-clone
4. **Backup exposure** - Old clones still contain secrets
5. **GitHub caches** - Deleted content may persist in GitHub's cache

### Why NOT Recommended

- The exposed master.key means credentials.yml.enc is compromised even if removed
- Multiple files across different commits increases cleanup complexity
- Risk of missing something is too high given the consequences

---

## Option B: Fresh Repository (RECOMMENDED)

### Process

1. **Prepare current codebase**
   - Remove/sanitize all sensitive files
   - Update configuration templates
   - Test application works without committed secrets

2. **Create new repository**
   - Initialize fresh git repo
   - Copy sanitized codebase
   - Single initial commit

3. **Archive old repository**
   - Make private
   - Add warning to README
   - Keep for historical reference only

### Advantages

1. **Clean slate** - Zero risk of leaked credentials
2. **No history concerns** - All secrets are provably absent
3. **Simple verification** - Easy to audit single commit
4. **Better security posture** - Demonstrates security awareness

---

## Pre-Public Checklist

Before making ANY repository public, complete these steps:

### Credential Rotation (MANDATORY)

- [ ] **Rails master.key** - Generate new key, re-encrypt credentials
- [ ] **Stripe API keys** - Roll in Stripe Dashboard (both test and live)
- [ ] **All OAuth credentials** - Regenerate for all 6 providers
- [ ] **Database password** - Change in production
- [ ] **Hetzner S3 keys** - Rotate access keys
- [ ] **Resend API key** - Regenerate
- [ ] **OpenRouter API key** - Regenerate

### Files to Remove/Sanitize

```
Files to DELETE entirely:
- config/master.key
- .kamal/secrets (recreate from template)
- docs/archive/STRIPE_SETUP.md (or heavily redact)

Files to SANITIZE:
- config/deploy.yml → Replace IPs/account IDs with placeholders
- .kamal/hooks/pre-build → Remove 1Password account ID
```

### Configuration Templates to Create

1. **`.kamal/secrets.example`**
```bash
# Copy to .kamal/secrets and fill with your values
# NEVER commit the actual secrets file

SECRETS=$(kamal secrets fetch --adapter 1password --account YOUR_ACCOUNT_ID --from "YOUR_VAULT" ...)
```

2. **`config/deploy.yml.example`**
```yaml
servers:
  web:
    - YOUR_SERVER_IP

registry:
  server: YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com
```

### Infrastructure Hardening (Post-Exposure)

Since server IP and AWS account are already in git history:

- [ ] **Firewall rules** - Verify SSH is key-only, no password auth
- [ ] **Fail2ban** - Ensure active for SSH/web
- [ ] **AWS IAM** - Review ECR access policies, enable MFA
- [ ] **1Password** - Verify all users have 2FA, review access logs
- [ ] **Monitor** - Set up alerts for unusual activity

---

## Recommended Action Plan

### Phase 1: Immediate (Today)

1. **Rotate all credentials** (see checklist above)
2. **Update 1Password** with new values
3. **Redeploy application** with rotated credentials
4. **Verify application works** with new credentials

### Phase 2: Repository Preparation (1-2 days)

1. Create sanitized copies of sensitive files
2. Create `.example` template files
3. Update `.gitignore` to prevent future leaks
4. Test deployment with template files

### Phase 3: New Repository Creation

1. Create new GitHub repository (private initially)
2. Copy sanitized codebase (no `.git` directory)
3. Initialize fresh git history
4. Verify no sensitive data with automated scan
5. Make public only after verification

### Phase 4: Cleanup

1. Archive old repository (keep private)
2. Update any CI/CD references
3. Notify team of new repository
4. Document the migration

---

## Automated Secret Scanning

Add these tools to prevent future leaks:

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check for common secret patterns
if git diff --cached | grep -E "(sk_test_|sk_live_|pk_test_|pk_live_|whsec_|AKIA[0-9A-Z]{16})" > /dev/null; then
    echo "ERROR: Potential secret detected in commit"
    exit 1
fi

# Check for master.key
if git diff --cached --name-only | grep -q "master.key"; then
    echo "ERROR: master.key should never be committed"
    exit 1
fi
```

### GitHub Secret Scanning

Enable in repository settings:
- Settings → Code security and analysis → Secret scanning

### Gitleaks CI Integration

Add to `.github/workflows/ci.yml`:

```yaml
- name: Gitleaks
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Summary

| Option | Effort | Risk | Recommendation |
|--------|--------|------|----------------|
| A: Clean history | High | Medium-High | Not recommended |
| B: Fresh repo | Medium | Low | **Recommended** |

**Bottom Line**: The safest approach is to create a fresh repository with a sanitized initial commit. This eliminates any risk of historical credential exposure and provides a clean security posture for public release.

---

## Questions to Answer Before Proceeding

1. Are you willing to lose git history (commit messages, blame, etc.)?
2. Do you need to preserve any specific commits or branches?
3. Is the current production deployment stable enough to rotate all credentials?
4. Do you have backup access to all credential sources (OAuth providers, Stripe, AWS, etc.)?
