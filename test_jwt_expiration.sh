#!/bin/bash

echo "===================================="
echo "JWT 30-Day Expiration Test"
echo "===================================="
echo ""

# Generate unique email
EMAIL="test-$(date +%s)@example.com"

echo "1. Creating test user with email: $EMAIL"
echo ""

# Sign up and capture response
RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d "{
    \"user\": {
      \"email\": \"$EMAIL\",
      \"password\": \"password123\",
      \"password_confirmation\": \"password123\",
      \"name\": \"Test User\"
    }
  }")

# Check if signup was successful
if echo "$RESPONSE" | grep -q "token"; then
  echo "✓ User created successfully"
  echo ""

  # Extract token (works with or without jq)
  if command -v jq &> /dev/null; then
    TOKEN=$(echo "$RESPONSE" | jq -r '.token')
  else
    # Fallback parsing without jq
    TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
  fi

  echo "2. Token received:"
  echo "$TOKEN"
  echo ""

  echo "3. Decoding token and checking expiration..."
  echo ""

  # Decode and verify expiration
  rails runner "
  token = '$TOKEN'
  decoded = JsonWebToken.decode(token)

  if decoded.nil?
    puts '✗ FAIL: Could not decode token'
    exit 1
  end

  exp_time = Time.at(decoded['exp'])
  now = Time.now
  days_until_expiry = ((exp_time - now) / 86400).round(2)
  hours_until_expiry = ((exp_time - now) / 3600).round(2)

  puts '==== Token Details ===='
  puts 'User ID: ' + decoded['user_id'].to_s
  puts 'Email: ' + decoded['email']
  puts ''
  puts '==== Expiration Info ===='
  puts 'Issued at: ' + now.strftime('%Y-%m-%d %H:%M:%S %Z')
  puts 'Expires at: ' + exp_time.strftime('%Y-%m-%d %H:%M:%S %Z')
  puts ''
  puts 'Time until expiry:'
  puts '  - Hours: ' + hours_until_expiry.to_s
  puts '  - Days: ' + days_until_expiry.to_s
  puts ''
  puts 'Expected: ~30 days (720 hours)'
  puts ''

  if days_until_expiry >= 29.9 && days_until_expiry <= 30.1
    puts '✓ PASS: Token expires in ~30 days'
  else
    puts '✗ FAIL: Token does NOT expire in 30 days'
    puts '  Expected: 30 days'
    puts '  Got: ' + days_until_expiry.to_s + ' days'
  end
  "

  echo ""
  echo "4. Testing authenticated API call..."
  echo ""

  # Test authenticated request
  AUTH_RESPONSE=$(curl -s -X GET http://localhost:3000/api/v1/users/me \
    -H "Authorization: Bearer $TOKEN")

  if echo "$AUTH_RESPONSE" | grep -q "$EMAIL"; then
    echo "✓ PASS: Authenticated API call successful"
    echo "   User data retrieved correctly"
  else
    echo "✗ FAIL: Authenticated API call failed"
    echo "   Response: $AUTH_RESPONSE"
  fi

else
  echo "✗ FAIL: Could not create user"
  echo "Response: $RESPONSE"
fi

echo ""
echo "===================================="
echo "Test Complete"
echo "===================================="
