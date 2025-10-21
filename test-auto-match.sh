#!/bin/bash

# =====================================================================
# Auto-Match Testing Script
# =====================================================================
# Quick commands to test the complete auto-matching flow
# =====================================================================

set -e  # Exit on error

BASE_URL="http://localhost:3000"
COOKIE_FILE="test-cookies.txt"

echo "===================================================================="
echo "Auto-Match Testing Script"
echo "===================================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =====================================================================
# Test 1: Check server is running
# =====================================================================

echo "Test 1: Checking if server is running..."
if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/health" | grep -q "200\|404"; then
  echo -e "${GREEN}✓${NC} Server is running"
else
  echo -e "${RED}✗${NC} Server is not running. Start with: npm run dev"
  exit 1
fi
echo ""

# =====================================================================
# Test 2: Create test session
# =====================================================================

echo "Test 2: Creating test session for alice (fid: 11111)..."
RESPONSE=$(curl -s -X POST "$BASE_URL/api/dev/login" \
  -H "Content-Type: application/json" \
  -d '{"fid": 11111, "username": "alice"}' \
  -c "$COOKIE_FILE")

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✓${NC} Session created successfully"
  echo "Response: $RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
else
  echo -e "${RED}✗${NC} Failed to create session"
  echo "Response: $RESPONSE"
  exit 1
fi
echo ""

# =====================================================================
# Test 3: Verify session
# =====================================================================

echo "Test 3: Verifying session..."
SESSION_CHECK=$(curl -s -X GET "$BASE_URL/api/dev/login" -b "$COOKIE_FILE")

if echo "$SESSION_CHECK" | grep -q '"authenticated":true'; then
  echo -e "${GREEN}✓${NC} Session is valid"
  echo "Session: $SESSION_CHECK" | jq '.' 2>/dev/null || echo "$SESSION_CHECK"
else
  echo -e "${YELLOW}⚠${NC} Session check failed or not authenticated"
  echo "Response: $SESSION_CHECK"
fi
echo ""

# =====================================================================
# Test 4: Run auto-matching (authenticated)
# =====================================================================

echo "Test 4: Running auto-matching (authenticated endpoint)..."
MATCH_RESPONSE=$(curl -s -X POST "$BASE_URL/api/matches/auto-run" -b "$COOKIE_FILE")

if echo "$MATCH_RESPONSE" | grep -q '"success":true'; then
  MATCHES_CREATED=$(echo "$MATCH_RESPONSE" | jq -r '.result.matchesCreated' 2>/dev/null || echo "?")
  USERS_PROCESSED=$(echo "$MATCH_RESPONSE" | jq -r '.result.usersProcessed' 2>/dev/null || echo "?")

  if [ "$MATCHES_CREATED" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Auto-matching succeeded!"
    echo "  Users processed: $USERS_PROCESSED"
    echo "  Matches created: $MATCHES_CREATED"
  else
    echo -e "${YELLOW}⚠${NC} Auto-matching ran but created 0 matches"
    echo "  Users processed: $USERS_PROCESSED"
    echo "  Check if users are eligible or if there's a blocking condition"
  fi

  echo "Full response:"
  echo "$MATCH_RESPONSE" | jq '.' 2>/dev/null || echo "$MATCH_RESPONSE"
elif echo "$MATCH_RESPONSE" | grep -q '"error":"Auto-matching ran recently"'; then
  echo -e "${YELLOW}⚠${NC} Auto-matching was skipped (ran too recently)"
  echo "Response: $MATCH_RESPONSE" | jq '.' 2>/dev/null || echo "$MATCH_RESPONSE"
else
  echo -e "${RED}✗${NC} Auto-matching failed"
  echo "Response: $MATCH_RESPONSE"
fi
echo ""

# =====================================================================
# Test 5: Run via cron endpoint (if CRON_SECRET is set)
# =====================================================================

if [ -n "$CRON_SECRET" ]; then
  echo "Test 5: Running auto-matching via cron endpoint..."
  CRON_RESPONSE=$(curl -s -X POST "$BASE_URL/api/cron/auto-match" \
    -H "Authorization: Bearer $CRON_SECRET")

  if echo "$CRON_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✓${NC} Cron endpoint works"
    echo "$CRON_RESPONSE" | jq '.' 2>/dev/null || echo "$CRON_RESPONSE"
  else
    echo -e "${RED}✗${NC} Cron endpoint failed"
    echo "Response: $CRON_RESPONSE"
  fi
  echo ""
else
  echo "Test 5: Skipping cron endpoint test (CRON_SECRET not set)"
  echo ""
fi

# =====================================================================
# Summary
# =====================================================================

echo "===================================================================="
echo "Testing Complete!"
echo "===================================================================="
echo ""
echo "Next steps:"
echo "1. Check Supabase for new matches:"
echo "   SELECT * FROM matches WHERE status = 'proposed' ORDER BY created_at DESC LIMIT 1;"
echo ""
echo "2. Run verification SQL:"
echo "   psql \$DATABASE_URL -f verify-matching-works.sql"
echo ""
echo "3. Clean up test data when done:"
echo "   psql \$DATABASE_URL -f cleanup-test-matches.sql"
echo ""
echo "Cookie file saved to: $COOKIE_FILE"
echo "Use it for other authenticated requests:"
echo "  curl -X GET $BASE_URL/api/matches -b $COOKIE_FILE"
echo "===================================================================="

# Cleanup option
read -p "Delete cookie file? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm -f "$COOKIE_FILE"
  echo "Cookie file deleted"
fi
