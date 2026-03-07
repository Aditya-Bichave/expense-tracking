#!/bin/bash
# Exit on error
set -e

# This script mimics the CI/CD pipeline to test the web build locally.
# It uses the production .env variables to build the Flutter web app,
# then serves it using the local Express server.

# 1. Load environment variables
if [ -f .env ]; then
  echo "--- Loading .env ---"
  # Robust parser for .env files
  while read -r line || [ -n "$line" ]; do
    # Skip comments and blank lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    
    # Parse KEY=VALUE
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      # Remove potential surrounding quotes from value
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"
      export "$key"="$value"
    fi
  done < .env
else
  echo "Error: .env file not found. Please create one with SUPABASE_URL and SUPABASE_ANON_KEY."
  exit 1
fi

# 1.1 Validate critical environment variables
if [ -z "$SUPABASE_URL" ]; then
  echo "Error: SUPABASE_URL is missing in .env"
  exit 1
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "Error: SUPABASE_ANON_KEY is missing in .env"
  exit 1
fi

# 2. Build Flutter Web
echo "--- Building Flutter Web (Production Mode) ---"
flutter build web --release --pwa-strategy=none \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

# 3. Prepare Server Directory
echo "--- Updating server/public ---"
rm -rf server/public
mkdir -p server/public
cp -r build/web/* server/public/

# 4. Start the Server
echo "--- Starting Local Server ---"
cd server
if [ ! -d "node_modules" ]; then
  echo "--- Installing server dependencies ---"
  npm install
fi

echo "--- App will be available at http://localhost:10000 ---"
PORT=10000 node server.js
