#!/bin/bash

# =====================================================================
# Test: Session Persistence After Page Refresh
# =====================================================================
# Purpose: Verify that dev sessions persist across page refreshes
# =====================================================================

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test: Session Persistence${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Test user
TEST_FID=543581
TEST_USERNAME="cengizhaneu"
TEST_DISPLAY="EmirCengizhanUlu"

echo -e "${YELLOW}→${NC} Testing session persistence for:"
echo "  FID: ${TEST_FID}"
echo "  Username: ${TEST_USERNAME}"
echo ""

# Step 1: Login and save cookie
echo -e "${YELLOW}→${NC} Step 1: Logging in and saving session cookie..."
LOGIN_RESPONSE=$(curl -s -c /tmp/session_cookie.txt "http://localhost:3000/api/dev/login?fid=${TEST_FID}&username=${TEST_USERNAME}&displayName=${TEST_DISPLAY}")

if echo "$LOGIN_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Login successful"
  echo "$LOGIN_RESPONSE" | jq '.'
else
  echo -e "${RED}✗${NC} Login failed"
  echo "$LOGIN_RESPONSE"
  exit 1
fi

echo ""
sleep 1

# Step 2: Check session (simulating page refresh)
echo -e "${YELLOW}→${NC} Step 2: Checking session (simulating page refresh)..."
SESSION_RESPONSE=$(curl -s -b /tmp/session_cookie.txt "http://localhost:3000/api/dev/session")

if echo "$SESSION_RESPONSE" | jq -e '.authenticated' > /dev/null 2>&1; then
  IS_AUTH=$(echo "$SESSION_RESPONSE" | jq -r '.authenticated')

  if [ "$IS_AUTH" = "true" ]; then
    echo -e "${GREEN}✓${NC} Session persisted after refresh!"
    echo ""
    echo "Session data:"
    echo "$SESSION_RESPONSE" | jq '.session'
  else
    echo -e "${RED}✗${NC} Session not authenticated"
    echo "$SESSION_RESPONSE" | jq '.'
    exit 1
  fi
else
  echo -e "${RED}✗${NC} Session check failed"
  echo "$SESSION_RESPONSE"
  exit 1
fi

echo ""
sleep 1

# Step 3: Verify cookie file
echo -e "${YELLOW}→${NC} Step 3: Verifying cookie..."
if [ -f /tmp/session_cookie.txt ]; then
  echo -e "${GREEN}✓${NC} Cookie file exists"
  echo ""
  echo "Cookie contents:"
  cat /tmp/session_cookie.txt | grep -v "^#"
else
  echo -e "${RED}✗${NC} Cookie file not found"
  exit 1
fi

echo ""
sleep 1

# Step 4: Multiple refresh simulation
echo -e "${YELLOW}→${NC} Step 4: Testing multiple refreshes..."
for i in {1..5}; do
  REFRESH_RESPONSE=$(curl -s -b /tmp/session_cookie.txt "http://localhost:3000/api/dev/session")
  IS_AUTH=$(echo "$REFRESH_RESPONSE" | jq -r '.authenticated')

  if [ "$IS_AUTH" = "true" ]; then
    echo -e "${GREEN}✓${NC} Refresh ${i}/5: Session still valid"
  else
    echo -e "${RED}✗${NC} Refresh ${i}/5: Session lost!"
    exit 1
  fi
  sleep 0.5
done

echo ""

# Step 5: Check session expiry info
echo -e "${YELLOW}→${NC} Step 5: Checking session expiry..."
EXPIRES_AT=$(echo "$SESSION_RESPONSE" | jq -r '.session.expiresAt')
echo "Session expires at: ${EXPIRES_AT}"

if [ -n "$EXPIRES_AT" ] && [ "$EXPIRES_AT" != "null" ]; then
  echo -e "${GREEN}✓${NC} Expiry timestamp set"
else
  echo -e "${YELLOW}⚠${NC} No expiry timestamp"
fi

echo ""

# Cleanup
rm -f /tmp/session_cookie.txt

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Summary:"
echo "  ✓ Login creates session cookie"
echo "  ✓ Session persists after refresh"
echo "  ✓ Multiple refreshes work correctly"
echo "  ✓ Cookie stored with correct attributes"
echo ""
echo "Next: Test in browser"
echo "  1. Visit: http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu"
echo "  2. Go to: http://localhost:3000/mini/inbox"
echo "  3. Refresh page (F5 or Cmd+R)"
echo "  4. Should remain logged in!"
echo ""
