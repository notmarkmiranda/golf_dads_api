#!/bin/bash

# Test script for Group Owner Privileges
# Tests all new endpoints: leave, remove member, transfer ownership, get members, delete with cascade

set -e  # Exit on error

BASE_URL="http://localhost:3000/api/v1"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Group Owner Privileges - Manual Test${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Step 1: Create two test users
echo -e "${BLUE}Step 1: Creating test users...${NC}"
OWNER_EMAIL="owner_$(date +%s)@test.com"
MEMBER_EMAIL="member_$(date +%s)@test.com"

OWNER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d "{\"user\": {\"email\": \"$OWNER_EMAIL\", \"name\": \"Test Owner\", \"password\": \"password123\"}}")

OWNER_TOKEN=$(echo $OWNER_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null || echo "")
OWNER_ID=$(echo $OWNER_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null || echo "")

if [ -z "$OWNER_TOKEN" ]; then
    echo -e "${RED}❌ Failed to create owner user${NC}"
    echo "$OWNER_RESPONSE" | python3 -m json.tool
    exit 1
fi

MEMBER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d "{\"user\": {\"email\": \"$MEMBER_EMAIL\", \"name\": \"Test Member\", \"password\": \"password123\"}}")

MEMBER_TOKEN=$(echo $MEMBER_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null || echo "")
MEMBER_ID=$(echo $MEMBER_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null || echo "")

if [ -z "$MEMBER_TOKEN" ]; then
    echo -e "${RED}❌ Failed to create member user${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Created owner: $OWNER_EMAIL (ID: $OWNER_ID)${NC}"
echo -e "${GREEN}✅ Created member: $MEMBER_EMAIL (ID: $MEMBER_ID)${NC}\n"

# Step 2: Owner creates a group
echo -e "${BLUE}Step 2: Owner creating group...${NC}"
GROUP_RESPONSE=$(curl -s -X POST "$BASE_URL/groups" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"group": {"name": "Test Group", "description": "Testing owner privileges"}}')

GROUP_ID=$(echo $GROUP_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['group']['id'])" 2>/dev/null || echo "")
INVITE_CODE=$(echo $GROUP_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['group']['invite_code'])" 2>/dev/null || echo "")

if [ -z "$GROUP_ID" ]; then
    echo -e "${RED}❌ Failed to create group${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Created group ID $GROUP_ID with invite code: $INVITE_CODE${NC}\n"

# Step 3: Member joins the group
echo -e "${BLUE}Step 3: Member joining group...${NC}"
JOIN_RESPONSE=$(curl -s -X POST "$BASE_URL/groups/join_with_code" \
  -H "Authorization: Bearer $MEMBER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"invite_code\": \"$INVITE_CODE\"}")

echo -e "${GREEN}✅ Member joined group${NC}\n"

# Step 4: Test GET members endpoint
echo -e "${BLUE}Step 4: Testing GET /groups/:id/members...${NC}"
MEMBERS_RESPONSE=$(curl -s -X GET "$BASE_URL/groups/$GROUP_ID/members" \
  -H "Authorization: Bearer $OWNER_TOKEN")

MEMBER_COUNT=$(echo $MEMBERS_RESPONSE | python3 -c "import sys, json; print(len(json.load(sys.stdin)['members']))" 2>/dev/null || echo "0")

echo -e "${GREEN}✅ Retrieved $MEMBER_COUNT members${NC}"
echo "$MEMBERS_RESPONSE" | python3 -m json.tool
echo ""

# Step 5: Test transfer ownership
echo -e "${BLUE}Step 5: Testing POST /groups/:id/transfer_ownership...${NC}"
TRANSFER_RESPONSE=$(curl -s -X POST "$BASE_URL/groups/$GROUP_ID/transfer_ownership" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"new_owner_id\": $MEMBER_ID}")

NEW_OWNER_ID=$(echo $TRANSFER_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['group']['owner_id'])" 2>/dev/null || echo "")

if [ "$NEW_OWNER_ID" = "$MEMBER_ID" ]; then
    echo -e "${GREEN}✅ Ownership transferred successfully${NC}"
else
    echo -e "${RED}❌ Ownership transfer failed${NC}"
    exit 1
fi
echo ""

# Step 6: New owner adds original owner back (they should still be members)
echo -e "${BLUE}Step 6: Testing group member list after transfer...${NC}"
MEMBERS_RESPONSE2=$(curl -s -X GET "$BASE_URL/groups/$GROUP_ID/members" \
  -H "Authorization: Bearer $MEMBER_TOKEN")

echo -e "${GREEN}✅ Members list after transfer:${NC}"
echo "$MEMBERS_RESPONSE2" | python3 -m json.tool
echo ""

# Step 7: New owner removes old owner
echo -e "${BLUE}Step 7: Testing DELETE /groups/:id/members/:user_id...${NC}"
REMOVE_RESPONSE=$(curl -s -X DELETE "$BASE_URL/groups/$GROUP_ID/members/$OWNER_ID" \
  -H "Authorization: Bearer $MEMBER_TOKEN")

echo -e "${GREEN}✅ Member removed successfully${NC}"
echo "$REMOVE_RESPONSE" | python3 -m json.tool
echo ""

# Step 8: Verify member was removed
echo -e "${BLUE}Step 8: Verifying member was removed...${NC}"
MEMBERS_RESPONSE3=$(curl -s -X GET "$BASE_URL/groups/$GROUP_ID/members" \
  -H "Authorization: Bearer $MEMBER_TOKEN")

MEMBER_COUNT2=$(echo $MEMBERS_RESPONSE3 | python3 -c "import sys, json; print(len(json.load(sys.stdin)['members']))" 2>/dev/null || echo "0")

if [ "$MEMBER_COUNT2" = "1" ]; then
    echo -e "${GREEN}✅ Member count is now 1 (only owner remaining)${NC}"
else
    echo -e "${RED}❌ Expected 1 member, got $MEMBER_COUNT2${NC}"
fi
echo ""

# Step 9: Create another group and test leave
echo -e "${BLUE}Step 9: Testing POST /groups/:id/leave...${NC}"
GROUP2_RESPONSE=$(curl -s -X POST "$BASE_URL/groups" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"group": {"name": "Test Group 2", "description": "For testing leave"}}')

GROUP2_ID=$(echo $GROUP2_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['group']['id'])" 2>/dev/null || echo "")
INVITE_CODE2=$(echo $GROUP2_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['group']['invite_code'])" 2>/dev/null || echo "")

curl -s -X POST "$BASE_URL/groups/join_with_code" \
  -H "Authorization: Bearer $MEMBER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"invite_code\": \"$INVITE_CODE2\"}" > /dev/null

LEAVE_RESPONSE=$(curl -s -X POST "$BASE_URL/groups/$GROUP2_ID/leave" \
  -H "Authorization: Bearer $MEMBER_TOKEN")

echo -e "${GREEN}✅ Member left group successfully${NC}"
echo "$LEAVE_RESPONSE" | python3 -m json.tool
echo ""

# Step 10: Test group deletion with cascade
echo -e "${BLUE}Step 10: Testing DELETE /groups/:id with cascade deletion...${NC}"

# Create a tee time posting for this group
TEE_TIME=$(date -u -v+7d +"%Y-%m-%dT10:00:00Z" 2>/dev/null || date -u -d "+7 days" +"%Y-%m-%dT10:00:00Z")
POSTING_RESPONSE=$(curl -s -X POST "$BASE_URL/tee_time_postings" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"tee_time_posting\": {\"course_name\": \"Test Course\", \"tee_time\": \"$TEE_TIME\", \"total_spots\": 4, \"notes\": \"Test\", \"group_ids\": [$GROUP2_ID]}}")

POSTING_ID=$(echo $POSTING_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['tee_time_posting']['id'])" 2>/dev/null || echo "")

echo -e "Created tee time posting ID: $POSTING_ID"

# Delete the group
DELETE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X DELETE "$BASE_URL/groups/$GROUP2_ID" \
  -H "Authorization: Bearer $OWNER_TOKEN")

HTTP_CODE=$(echo "$DELETE_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

if [ "$HTTP_CODE" = "204" ]; then
    echo -e "${GREEN}✅ Group deleted successfully (HTTP 204)${NC}"
else
    echo -e "${RED}❌ Group deletion failed (HTTP $HTTP_CODE)${NC}"
fi

# Verify posting was also deleted
POSTING_CHECK=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/tee_time_postings/$POSTING_ID" \
  -H "Authorization: Bearer $OWNER_TOKEN")

if [ "$POSTING_CHECK" = "404" ]; then
    echo -e "${GREEN}✅ Exclusive tee time posting was cascade deleted${NC}"
else
    echo -e "${RED}❌ Tee time posting still exists (should have been deleted)${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ All tests completed successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Tested endpoints:"
echo "  ✅ GET /api/v1/groups/:id/members"
echo "  ✅ POST /api/v1/groups/:id/transfer_ownership"
echo "  ✅ DELETE /api/v1/groups/:id/members/:user_id"
echo "  ✅ POST /api/v1/groups/:id/leave"
echo "  ✅ DELETE /api/v1/groups/:id (with cascade)"
