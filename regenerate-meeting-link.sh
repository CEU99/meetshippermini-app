#!/bin/bash

# =====================================================================
# Script: Regenerate Meeting Link for Emir ↔ Aysu16 Match
# =====================================================================
# Usage: ./regenerate-meeting-link.sh [match-id]
# If no match-id provided, will try to auto-detect
# =====================================================================

set -e  # Exit on error

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Regenerate Meeting Link${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Supabase config (from .env.local)
SUPABASE_URL="https://mpsnsxmznxvoqcslcaom.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wc25zeG16bnh2b3Fjc2xjYW9tIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDgwMTAzMSwiZXhwIjoyMDc2Mzc3MDMxfQ.06fhNNLq6cjv_0Pc4FpvQxN4yIhB1oNmsy5HSgtouVg"

# Check if match ID provided
if [ -n "$1" ]; then
  MATCH_ID="$1"
  echo -e "${GREEN}✓${NC} Using provided match ID: ${MATCH_ID}"
else
  echo -e "${YELLOW}→${NC} No match ID provided, fetching Emir ↔ Aysu16 match..."

  # Fetch match ID from Supabase
  MATCH_ID=$(curl -s "${SUPABASE_URL}/rest/v1/matches?select=id&or=(and(user_a_fid.eq.543581,user_b_fid.eq.1394398),and(user_a_fid.eq.1394398,user_b_fid.eq.543581))&order=created_at.desc&limit=1" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" \
    | jq -r '.[0].id')

  if [ -z "$MATCH_ID" ] || [ "$MATCH_ID" = "null" ]; then
    echo -e "${RED}✗${NC} Could not find match between Emir (543581) and Aysu16 (1394398)"
    echo ""
    echo "Please provide match ID manually:"
    echo "  ./regenerate-meeting-link.sh <match-id>"
    exit 1
  fi

  echo -e "${GREEN}✓${NC} Found match ID: ${MATCH_ID}"
fi

echo ""
echo -e "${YELLOW}→${NC} Regenerating meeting link..."

# Call regenerate API endpoint
RESPONSE=$(curl -s -X POST "http://localhost:3000/api/matches/${MATCH_ID}/regenerate-link" \
  -H "Content-Type: application/json")

# Check if successful
if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  MEETING_LINK=$(echo "$RESPONSE" | jq -r '.meetingLink')

  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}✓ SUCCESS!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo -e "Meeting Link: ${GREEN}${MEETING_LINK}${NC}"
  echo ""

  # Identify provider
  if [[ "$MEETING_LINK" == *"whereby"* ]]; then
    echo -e "Provider: ${BLUE}Whereby${NC}"
  elif [[ "$MEETING_LINK" == *"huddle01"* ]]; then
    echo -e "Provider: ${BLUE}Huddle01${NC}"
  elif [[ "$MEETING_LINK" == *"meet.google.com"* ]]; then
    echo -e "Provider: ${BLUE}Google Meet${NC}"
  else
    echo -e "Provider: ${BLUE}Unknown${NC}"
  fi

  echo ""
  echo -e "${GREEN}Next steps:${NC}"
  echo "  1. Visit: http://localhost:3000/mini/inbox"
  echo "  2. Login as Emir or Aysu16"
  echo "  3. Click 'Join Meeting' button"
  echo "  4. Should open: ${MEETING_LINK}"
  echo ""

else
  ERROR=$(echo "$RESPONSE" | jq -r '.error // "Unknown error"')

  echo ""
  echo -e "${RED}========================================${NC}"
  echo -e "${RED}✗ FAILED${NC}"
  echo -e "${RED}========================================${NC}"
  echo ""
  echo -e "Error: ${RED}${ERROR}${NC}"
  echo ""
  echo -e "${YELLOW}Troubleshooting:${NC}"
  echo "  1. Ensure dev server is running: npm run dev"
  echo "  2. Check match ID is correct: ${MATCH_ID}"
  echo "  3. Verify both users accepted the match"
  echo "  4. Check logs in terminal for details"
  echo ""
  exit 1
fi
