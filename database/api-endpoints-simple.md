# Simplified API Endpoints for Cardano Social Wallet

## Overview
Simplified REST API for social wallet authentication and Cardano transaction signing only.

## Base URL
```
https://your-domain.com/api/v1
```

## Authentication
- Simple session tokens for signing permissions
- Token sent in `Authorization: Bearer <session_token>` header

## Endpoints

### 1. OAuth Authentication

#### POST /auth/{provider}/callback
Handle OAuth callback from social provider (Google, Discord, Twitter, Apple).

**Request Body:**
```json
{
  "code": "authorization_code_from_provider",
  "provider_user_info": {
    "provider_id": "123456789",
    "email": "user@gmail.com", 
    "username": "john_doe"
  }
}
```

**Response (New User):**
```json
{
  "status": "new_user",
  "user_id": "uuid",
  "requires_wallet_setup": true
}
```

**Response (Existing User):**
```json
{
  "status": "existing_user",
  "user_id": "uuid",
  "cardano_address": "addr1...",
  "network_id": 0
}
```

### 2. Wallet Management

#### POST /wallet/create
Create new Cardano wallet for authenticated user.

**Request Body:**
```json
{
  "user_id": "uuid",
  "recovery_question": "What was my first pet's name?",
  "recovery_answer": "Fluffy",
  "network_id": 0
}
```

**Response:**
```json
{
  "wallet_id": "wallet_uuid",
  "cardano_address": "addr1...",
  "seed_phrase": "abandon ability able about above absent absorb abstract absurd abuse access accident account accuse achieve acid acoustic acquire across act actual actor adapt add",
  "success": true
}
```

#### POST /wallet/unlock
Unlock wallet for signing transactions.

**Request Body:**
```json
{
  "user_id": "uuid",
  "recovery_answer": "Fluffy"
}
```

**Response:**
```json
{
  "session_token": "simple_session_token_here",
  "expires_at": "2024-01-01T01:00:00Z",
  "wallet_ready": true
}
```

### 3. Transaction Signing

#### POST /cardano/sign-tx
Sign Cardano transaction with unlocked wallet.

**Authorization:** Bearer token required (session_token)

**Request Body:**
```json
{
  "unsigned_transaction": "83a40081825820...",
  "partial_sign": false
}
```

**Response:**
```json
{
  "signed_transaction": "83a40081825820...",
  "transaction_hash": "a1b2c3d4e5f6...",
  "success": true
}
```

#### POST /cardano/sign-data
Sign arbitrary data with wallet.

**Authorization:** Bearer token required

**Request Body:**
```json
{
  "payload": "hex_encoded_data_to_sign",
  "address": "addr1..." 
}
```

**Response:**
```json
{
  "signature": "a85840...",
  "key": "a401010327...",
  "success": true
}
```

### 4. Session Management

#### DELETE /session
Invalidate signing session.

**Authorization:** Bearer token required

**Response:**
```json
{
  "status": "session_invalidated"
}
```

### 5. User Info

#### GET /user/{user_id}
Get basic user info and wallet status.

**Response:**
```json
{
  "user_id": "uuid",
  "provider": "google", 
  "email": "user@gmail.com",
  "username": "john_doe",
  "wallet": {
    "exists": true,
    "cardano_address": "addr1...",
    "network_id": 0
  },
  "created_at": "2024-01-01T00:00:00Z"
}
```

## Error Responses

```json
{
  "error": "INVALID_RECOVERY_ANSWER",
  "message": "The provided recovery answer is incorrect",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### Error Codes:
- `INVALID_RECOVERY_ANSWER`: Wrong recovery answer
- `WALLET_NOT_FOUND`: No wallet exists for user
- `SESSION_EXPIRED`: Signing session has expired
- `TRANSACTION_INVALID`: Invalid transaction format
- `USER_NOT_FOUND`: User doesn't exist

## Simplified Flow

### First Time Setup:
1. `POST /auth/google/callback` → Get user_id
2. `POST /wallet/create` → Create wallet + get seed phrase
3. `POST /wallet/unlock` → Get session token  
4. `POST /cardano/sign-tx` → Sign transactions

### Return User:
1. `POST /auth/google/callback` → Get existing user
2. `POST /wallet/unlock` → Get session token
3. `POST /cardano/sign-tx` → Sign transactions

## Security Notes

1. **Shamir Secret Sharing**: Private keys split into 2/3 shards
2. **Recovery Only**: Simple recovery question/answer mechanism  
3. **Session Tokens**: Short-lived tokens for signing operations only
4. **Cardano Only**: No multi-chain complexity
5. **No Audit Trail**: Minimal logging for simplicity

## Rate Limiting

- OAuth callbacks: 5 requests per minute per IP
- Transaction signing: 10 requests per minute per user
- Other endpoints: 20 requests per minute per user
