#!/bin/bash

# Load environment variables
if [ -f .env.local ]; then
  source .env.local
elif [ -f .env ]; then
  source .env
fi

# Extract Supabase project ref from URL
SUPABASE_URL="${NEXT_PUBLIC_SUPABASE_URL}"
PROJECT_REF=$(echo "$SUPABASE_URL" | sed -E 's|https://([^.]+)\.supabase\.co|\1|')

echo "================================================"
echo "Applying Match Decline Fix to Supabase Database"
echo "================================================"
echo ""
echo "Project: $PROJECT_REF"
echo ""
echo "Note: You'll need to apply this fix via Supabase Dashboard SQL Editor"
echo "      or provide your database password to connect via psql."
echo ""
echo "The fix is ready in: FIX_DECLINE_FINAL.sql"
echo ""
echo "To apply via Supabase Dashboard:"
echo "1. Go to https://supabase.com/dashboard/project/$PROJECT_REF/sql"
echo "2. Copy contents of FIX_DECLINE_FINAL.sql"
echo "3. Paste into SQL Editor"
echo "4. Click 'Run'"
echo ""
