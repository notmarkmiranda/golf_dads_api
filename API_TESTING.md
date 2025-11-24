# API Testing Guide

This guide shows how to test the Golf Dads API endpoints manually before the iOS app is ready.

## Base URL

- **Local Development:** `http://localhost:3000`
- **Production:** `https://your-app-name.onrender.com` (replace with your actual Render URL)

## Authentication Endpoints

### 1. Sign Up (Create New User)

```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "name": "Test User"
    }
  }'
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "test@example.com",
    "name": "Test User",
    "avatar_url": null,
    "provider": null
  }
}
```

### 2. Login (Existing User)

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**Expected Response:** Same as signup

### 3. Google Sign-In

For testing Google OAuth, you'll need a real Google ID token from the iOS app or web Google Sign-In. This cannot be easily tested with curl alone.

```bash
curl -X POST http://localhost:3000/api/auth/google \
  -H "Content-Type: application/json" \
  -d '{
    "token": "GOOGLE_ID_TOKEN_HERE"
  }'
```

## Using Authentication Tokens

After signing up or logging in, save the token from the response. Use it in subsequent requests:

```bash
# Save token to variable
TOKEN="eyJhbGciOiJIUzI1NiJ9..."

# Use token in authenticated requests (for future endpoints)
curl -X GET http://localhost:3000/api/groups \
  -H "Authorization: Bearer $TOKEN"
```

## Testing with Postman

1. **Import Collection:**
   - Download [Postman](https://www.postman.com/)
   - Create a new collection called "Golf Dads API"
   - Set base URL as collection variable

2. **Setup Environment:**
   - Create "Local" environment: `http://localhost:3000`
   - Create "Production" environment: `https://your-app.onrender.com`
   - Add `token` variable to store JWT after login

3. **Add Requests:**
   - POST `/api/auth/signup` - Sign Up
   - POST `/api/auth/login` - Login
   - POST `/api/auth/google` - Google Sign-In

4. **Auto-save Token:**
   In signup/login requests, add this to the "Tests" tab:
   ```javascript
   if (pm.response.code === 200 || pm.response.code === 201) {
     const jsonData = pm.response.json();
     pm.environment.set("token", jsonData.token);
   }
   ```

5. **Use Token:**
   In future authenticated requests, add header:
   - Key: `Authorization`
   - Value: `Bearer {{token}}`

## Testing with HTTPie (Cleaner Alternative to curl)

Install: `brew install httpie`

### Sign Up
```bash
http POST localhost:3000/api/auth/signup \
  user:='{"email":"test@example.com","password":"password123","password_confirmation":"password123","name":"Test User"}'
```

### Login
```bash
http POST localhost:3000/api/auth/login \
  email=test@example.com \
  password=password123
```

### Authenticated Request (after getting token)
```bash
http GET localhost:3000/api/groups \
  "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Quick Test Script

Create a file `test_api.sh`:

```bash
#!/bin/bash

BASE_URL="http://localhost:3000"

echo "Testing API endpoints..."
echo ""

# Test signup
echo "1. Testing signup..."
SIGNUP_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test'$RANDOM'@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "name": "Test User"
    }
  }')

echo $SIGNUP_RESPONSE | jq '.'
TOKEN=$(echo $SIGNUP_RESPONSE | jq -r '.token')
echo "Token: $TOKEN"
echo ""

# Test login
echo "2. Testing login..."
curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }' | jq '.'

echo ""
echo "Tests complete!"
```

Make it executable: `chmod +x test_api.sh`

Run it: `./test_api.sh`

## Health Check

Test if the API is running:

```bash
curl http://localhost:3000/up
```

Should return: `200 OK`

## Admin Dashboard

Access the Avo admin panel to view/manage data:
- Local: http://localhost:3000/avo
- Production: https://your-app.onrender.com/avo

## Troubleshooting

### Token Expired
If you get a 401 error, your token may have expired (24-hour lifetime). Login again to get a new token.

### CORS Errors
CORS is configured for the iOS app. If testing from a browser, you may encounter CORS issues. Use curl/Postman instead.

### Server Not Running
- Local: Run `rails server`
- Production: Check Render dashboard for deployment status
