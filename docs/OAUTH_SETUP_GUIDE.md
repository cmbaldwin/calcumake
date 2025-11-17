# OAuth Provider Setup Guide for CalcuMake

This document contains all the information needed to set up OAuth authentication for CalcuMake with 6 major providers.

## Overview

CalcuMake supports OAuth authentication with the following providers:

- Google OAuth2
- GitHub OAuth
- Microsoft Graph OAuth
- Facebook OAuth
- Yahoo Japan OAuth
- LINE OAuth

## Provider Setup Instructions

### 1. Google OAuth2

**Console URL:** https://console.cloud.google.com/apis/credentials

**Setup Steps:**

1. Create or select a Google Cloud project
2. Go to APIs & Services → Credentials
3. Create OAuth 2.0 Client ID
4. Configure OAuth consent screen if needed
5. Set application type to "Web application"

**Redirect URIs:**

- Development: `http://localhost:3000/users/auth/google_oauth2/callback`
- Production: `https://calcumake.com/users/auth/google_oauth2/callback`

**Required Scopes:**

- `email`
- `profile`
- `openid` (automatically included)

**Environment Variables:**

- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_OAUTH_CLIENT_SECRET`

**1Password Vault Keys:**

- `CALCUMAKE_GOOGLE_OAUTH_CLIENT_ID`
- `CALCUMAKE_GOOGLE_OAUTH_CLIENT_SECRET`

---

### 2. GitHub OAuth

**Console URL:** https://github.com/settings/developers

**Setup Steps:**

1. Go to Settings → Developer settings → OAuth Apps
2. Click "Register a new application"
3. Fill in application details

**Redirect URIs:**

- Development: `http://localhost:3000/users/auth/github/callback`
- Production: `https://calcumake.com/users/auth/github/callback`

**Required Scopes:**

- `user:email`

**Environment Variables:**

- `GITHUB_OAUTH_CLIENT_ID`
- `GITHUB_OAUTH_CLIENT_SECRET`

**1Password Vault Keys:**

- `CALCUMAKE_GITHUB_OAUTH_CLIENT_ID`
- `CALCUMAKE_GITHUB_OAUTH_CLIENT_SECRET`

---

### 3. Microsoft Graph OAuth

**Console URL:** https://portal.azure.com

**Setup Steps:**

1. Go to Microsoft Entra ID (Azure Active Directory)
2. Navigate to App registrations → New registration
3. Choose supported account types
4. Add redirect URIs in Authentication section
5. Create client secret in Certificates & secrets
6. Configure API permissions for Microsoft Graph

**Redirect URIs:**

- Development: `http://localhost:3000/users/auth/microsoft_graph/callback`
- Production: `https://calcumake.com/users/auth/microsoft_graph/callback`

**Required Scopes/Permissions:**

- `openid`
- `email`
- `profile`
- `User.Read`

**Environment Variables:**

- `MICROSOFT_OAUTH_CLIENT_ID`
- `MICROSOFT_OAUTH_CLIENT_SECRET`

**1Password Vault Keys:**

- `CALCUMAKE_MICROSOFT_OAUTH_CLIENT_ID`
- `CALCUMAKE_MICROSOFT_OAUTH_CLIENT_SECRET`

---

### 4. Facebook OAuth

**Console URL:** https://developers.facebook.com/apps/

**Setup Steps:**

1. Create a new app or select existing app
2. Add Facebook Login product
3. Configure OAuth redirect URIs in Facebook Login settings
4. Set up app domains and privacy policy URL

**Redirect URIs:**

- Development: `http://localhost:3000/users/auth/facebook/callback`
- Production: `https://calcumake.com/users/auth/facebook/callback`

**Required Scopes:**

- `email`
- `public_profile`

**Environment Variables:**

- `FACEBOOK_OAUTH_CLIENT_ID`
- `FACEBOOK_OAUTH_CLIENT_SECRET`

**1Password Vault Keys:**

- `CALCUMAKE_FACEBOOK_OAUTH_CLIENT_ID`
- `CALCUMAKE_FACEBOOK_OAUTH_CLIENT_SECRET`

---

### 5. Yahoo Japan OAuth

**Console URL:** https://developer.yahoo.co.jp/

**Setup Steps:**

1. Create Yahoo Japan developer account
2. Register new application
3. Configure OAuth redirect URIs
4. Set required scopes

**Redirect URIs:**

- Development: `http://localhost:3000/users/auth/yahoojp/callback`
- Production: `https://calcumake.com/users/auth/yahoojp/callback`

**Required Scopes:**

- `openid`
- `email`
- `profile`

**Environment Variables:**

- `YAHOOJP_OAUTH_CLIENT_ID`
- `YAHOOJP_OAUTH_CLIENT_SECRET`

**1Password Vault Keys:**

- `CALCUMAKE_YAHOOJP_OAUTH_CLIENT_ID`
- `CALCUMAKE_YAHOOJP_OAUTH_CLIENT_SECRET`

---

### 6. LINE OAuth

**Console URL:** https://developers.line.biz/console/

**Setup Steps:**

1. Create LINE Developers account
2. Create a new provider (if needed)
3. Create a new LINE Login channel
4. Configure callback URLs in LINE Login settings
5. Get Channel ID and Channel Secret

**Redirect URIs:**

- Development: `http://localhost:3000/users/auth/line/callback`
- Production: `https://calcumake.com/users/auth/line/callback`

**Required Scopes:**

- `profile`
- `openid`
- `email`

**Environment Variables:**

- `LINE_OAUTH_CHANNEL_ID`
- `LINE_OAUTH_CHANNEL_SECRET`

**1Password Vault Keys:**

- `CALCUMAKE_LINE_OAUTH_CHANNEL_ID`
- `CALCUMAKE_LINE_OAUTH_CHANNEL_SECRET`

---

## Development Setup

For local development, you can set environment variables directly:

```bash
export GOOGLE_OAUTH_CLIENT_ID="your_google_client_id"
export GOOGLE_OAUTH_CLIENT_SECRET="your_google_client_secret"
export GITHUB_OAUTH_CLIENT_ID="your_github_client_id"
export GITHUB_OAUTH_CLIENT_SECRET="your_github_client_secret"
export MICROSOFT_OAUTH_CLIENT_ID="your_microsoft_client_id"
export MICROSOFT_OAUTH_CLIENT_SECRET="your_microsoft_client_secret"
export FACEBOOK_OAUTH_CLIENT_ID="your_facebook_client_id"
export FACEBOOK_OAUTH_CLIENT_SECRET="your_facebook_client_secret"
export YAHOOJP_OAUTH_CLIENT_ID="your_yahoojp_client_id"
export YAHOOJP_OAUTH_CLIENT_SECRET="your_yahoojp_client_secret"
export LINE_OAUTH_CHANNEL_ID="your_LINE_OAUTH_CHANNEL_ID"
export LINE_OAUTH_CHANNEL_SECRET="your_LINE_OAUTH_CHANNEL_SECRET"
```

## Production Deployment

### 1Password Integration

All OAuth credentials are managed through 1Password. Add the following keys to your "MOAB/Production" vault:

```
CALCUMAKE_GOOGLE_OAUTH_CLIENT_ID
CALCUMAKE_GOOGLE_OAUTH_CLIENT_SECRET
CALCUMAKE_GITHUB_OAUTH_CLIENT_ID
CALCUMAKE_GITHUB_OAUTH_CLIENT_SECRET
CALCUMAKE_MICROSOFT_OAUTH_CLIENT_ID
CALCUMAKE_MICROSOFT_OAUTH_CLIENT_SECRET
CALCUMAKE_FACEBOOK_OAUTH_CLIENT_ID
CALCUMAKE_FACEBOOK_OAUTH_CLIENT_SECRET
CALCUMAKE_YAHOOJP_OAUTH_CLIENT_ID
CALCUMAKE_YAHOOJP_OAUTH_CLIENT_SECRET
CALCUMAKE_LINE_OAUTH_CHANNEL_ID
CALCUMAKE_LINE_OAUTH_CHANNEL_SECRET
```

### Kamal Deployment

The `.kamal/secrets` file is already configured to fetch these credentials from 1Password during deployment.

## Testing OAuth Integration

1. Start the development server: `bin/dev`
2. Navigate to `http://localhost:3000/users/sign_in`
3. Test each OAuth provider button
4. Verify successful authentication and user creation

## Security Considerations

- Never commit OAuth secrets to version control
- Use HTTPS in production redirect URIs
- Regularly rotate OAuth credentials
- Monitor OAuth usage and failed attempts
- Ensure proper scope minimization for each provider

## Troubleshooting

### Common Issues

1. **Redirect URI Mismatch**: Ensure exact match between configured URIs and actual callback URLs
2. **Invalid Client**: Verify client ID and secret are correct
3. **Scope Errors**: Check that requested scopes are approved for your application
4. **CSRF Errors**: Ensure `omniauth-rails_csrf_protection` gem is installed

### Debug Information

OAuth routes available in the application:

- `/users/auth/google_oauth2`
- `/users/auth/github`
- `/users/auth/microsoft_graph`
- `/users/auth/facebook`
- `/users/auth/yahoojp`
- `/users/auth/line`

Callback URLs:

- `/users/auth/google_oauth2/callback`
- `/users/auth/github/callback`
- `/users/auth/microsoft_graph/callback`
- `/users/auth/facebook/callback`
- `/users/auth/yahoojp/callback`
- `/users/auth/line/callback`

## Provider-Specific Notes

### Google

- Requires OAuth consent screen configuration
- May require domain verification for production
- Supports incremental authorization

### GitHub

- Supports organization restrictions
- Can request specific repository access
- Rate limiting applies to OAuth endpoints

### Microsoft

- Supports both personal and work/school accounts
- Requires tenant-specific configuration for enterprise
- Advanced security features available

### Facebook

- Requires app review for certain permissions
- Must provide privacy policy URL
- Subject to Facebook's platform policies

### Yahoo Japan

- Primarily for Japanese market
- Documentation may be in Japanese
- Different privacy and data handling requirements

---

_Last updated: November 2025_
_CalcuMake OAuth Integration v1.0_
