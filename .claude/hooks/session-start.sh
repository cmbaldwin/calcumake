#!/bin/bash
# SessionStart hook for Claude Code on the web
# Installs all dependencies needed to run CI tests in remote environments

set -euo pipefail

# Only run in remote Claude Code environments (web sessions)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  echo "Skipping hook - not running in Claude Code remote environment"
  exit 0
fi

echo "🚀 SessionStart: Setting up development environment..."
echo ""

# Install Ruby dependencies (gems)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💎 Installing Ruby dependencies (bundler)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Check if gems are already installed, install if not
if bundle check > /dev/null 2>&1; then
  echo "✅ Ruby gems already installed"
else
  # Disable warnings about running as root (unavoidable in containers)
  if bundle install --quiet; then
    echo "✅ Ruby gems installed"
  else
    echo "⚠️  Bundle install had issues, but continuing..."
  fi
fi
echo ""

# Install JavaScript dependencies (npm)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Installing JavaScript dependencies (npm)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if npm install; then
  echo "✅ npm packages installed"
else
  echo "❌ npm install failed"
  exit 1
fi
echo ""

# Prepare test database
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗄️  Preparing test database..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if RAILS_ENV=test bin/rails db:prepare; then
  echo "✅ Test database ready"
else
  echo "❌ Database preparation failed"
  exit 1
fi
echo ""

# Set environment variables for the session
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Configuring environment variables..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  # Set Rails environment for testing
  echo 'export RAILS_ENV=test' >> "$CLAUDE_ENV_FILE"
  # Disable bootsnap warnings in test environment
  echo 'export BOOTSNAP_LOG_LEVEL=error' >> "$CLAUDE_ENV_FILE"
  echo "✅ Environment configured"
else
  echo "⚠️  CLAUDE_ENV_FILE not available - skipping environment configuration"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SessionStart complete! Environment ready for CI testing."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Available commands:"
echo "  • bin/ci                - Run all CI checks"
echo "  • bin/rails test        - Run Rails tests"
echo "  • npm test              - Run Jest tests"
echo "  • bin/rubocop           - Run linter"
echo "  • bin/brakeman          - Run security scan"
echo ""
