# API Endpoints for Social Wallet Authentication

## Overview
This document describes the REST API endpoints for social wallet authentication and management.

## Base URL
```
https://your-domain.com/api/v1
```

## Authentication
- JWT tokens required for protected endpoints
- Token sent in `Authorization: Bearer <jwt_token>` header

## Endpoints

### 1. OAuth Authentication

#### GET /auth/{provider}
Initiate OAuth flow with social provider.

**Parameters:**
- `provider` (path): Social provider (`google`, `discord`, `twitter`, `apple`)
- `redirect_uri` (query): URL to redirect after authentication

**Response:**
```json
{
  "auth_url": "https://accounts.google.com/oauth/authorize?..."
}
```

#### POST /auth/{provider}/callback
Handle OAuth callback from social provider.

**Request Body:**
```json
{
  "code": "authorization_code_from_provider",
  "state": "encoded_state_parameter"
}
```

**Response (New User):**
```json
{
  "status": "new_user",
  "user": {
    "id": "uuid",
    "provider": "google",
    "email": "user@gmail.com",
    "username": "john_doe",
    "avatar_url": "https://..."
  },
  "requires_wallet_setup": true
}
```

**Response (Existing User):**
```json
{
  "status": "existing_user",
  "user": {
    "id": "uuid",
    "provider": "google",
    "email": "user@gmail.com",
    "username": "john_doe"
  },
  "wallet": {
    "id": "wallet_uuid",
    "cardano_address": "addr1...",
    "bitcoin_address": "bc1...",
    "spark_address": "spark..."
  },
  "jwt_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_at": "2024-01-01T00:00:00Z"
}
```

### 2. Wallet Management

#### POST /wallet/create
Create new wallet for authenticated user (first-time setup).

**Authorization:** Bearer token required

**Request Body:**
```json
{
  "recovery_question": "What was my first pet's name?",
  "recovery_answer": "Fluffy",
  "device_fingerprint": "unique_device_id",
  "device_name": "iPhone 13"
}
```

**Response:**
```json
{
  "wallet": {
    "id": "wallet_uuid",
    "cardano_address": "addr1...",
    "bitcoin_testnet_address": "tb1...",
    "spark_regtest_address": "spark...",
    "network_id": 0
  },
  "seed_phrase": "abandon ability able about above absent absorb absorb abstract absurd abuse access accident account accuse achieve acid acoustic acquire across act actual actor adapt add",
  "device_shard": "encrypted_device_shard_here"
}
```

#### POST /wallet/unlock
Unlock wallet for signing transactions.

**Authorization:** Bearer token required

**Request Body (Option 1 - Recovery Answer):**
```json
{
  "method": "recovery_answer",
  "recovery_answer": "Fluffy"
}
```

**Request Body (Option 2 - Device Shard):**
```json
{
  "method": "device_shard",
  "device_fingerprint": "unique_device_id",
  "device_shard": "encrypted_device_shard_here"
}
```

**Request Body (Option 3 - WebAuthN):**
```json
{
  "method": "webauthn",
  "credential_id": "webauthn_credential_id"
}
```

**Response:**
```json
{
  "session_id": "wallet_session_uuid",
  "expires_at": "2024-01-01T01:00:00Z",
  "wallet_ready": true
}
```

### 3. Transaction Operations

#### POST /wallet/sign/{chain}
Sign transaction with unlocked wallet.

**Authorization:** Bearer token + Wallet session required

**Parameters:**
- `chain` (path): Blockchain (`cardano`, `bitcoin`, `spark`)

**Request Body (Cardano):**
```json
{
  "unsigned_transaction": "83a4...",
  "partial_sign": false,
  "return_full_tx": true
}
```

**Request Body (Bitcoin):**
```json
{
  "psbt": "cHNidP8B...",
  "sign_inputs": [0, 1],
  "broadcast": false
}
```

**Response:**
```json
{
  "signed_transaction": "83a4...",
  "transaction_hash": "tx_hash_here"
}
```

#### POST /wallet/transfer/{chain}
Send transfer transaction.

**Authorization:** Bearer token + Wallet session required

**Request Body (Bitcoin):**
```json
{
  "recipients": [
    {
      "address": "bc1q...",
      "amount": 100000
    }
  ]
}
```

**Response:**
```json
{
  "txid": "transaction_id_here",
  "status": "success"
}
```

### 4. Recovery & Export

#### POST /wallet/recover
Recover wallet using seed phrase.

**Request Body:**
```json
{
  "seed_phrase": "abandon ability able about above absent...",
  "new_recovery_question": "What's my mother's maiden name?",
  "new_recovery_answer": "Smith",
  "device_fingerprint": "new_device_id"
}
```

**Response:**
```json
{
  "wallet": {
    "id": "wallet_uuid",
    "addresses": { ... }
  },
  "recovered": true,
  "new_device_shard": "encrypted_shard_here"
}
```

#### POST /wallet/export
Export wallet (user confirmation required).

**Authorization:** Bearer token + Wallet session required

**Request Body:**
```json
{
  "chain": "cardano",
  "confirmation": "user_confirmed_export"
}
```

**Response:**
```json
{
  "status": "export_initiated",
  "export_id": "export_request_uuid"
}
```

### 5. Session Management

#### POST /session/refresh
Refresh JWT token.

**Request Body:**
```json
{
  "refresh_token": "current_refresh_token"
}
```

**Response:**
```json
{
  "jwt_token": "new_jwt_token",
  "refresh_token": "new_refresh_token",
  "expires_at": "2024-01-01T00:00:00Z"
}
```

#### DELETE /session
Logout user and invalidate tokens.

**Authorization:** Bearer token required

**Response:**
```json
{
  "status": "logged_out"
}
```

### 6. User Profile

#### GET /user/profile
Get user profile information.

**Authorization:** Bearer token required

**Response:**
```json
{
  "id": "user_uuid",
  "provider": "google",
  "email": "user@gmail.com",
  "username": "john_doe",
  "avatar_url": "https://...",
  "created_at": "2024-01-01T00:00:00Z",
  "last_login_at": "2024-01-01T12:00:00Z",
  "wallet": {
    "id": "wallet_uuid",
    "network_id": 0,
    "created_at": "2024-01-01T00:30:00Z"
  }
}
```

#### PUT /user/profile
Update user profile.

**Authorization:** Bearer token required

**Request Body:**
```json
{
  "username": "new_username",
  "avatar_url": "https://new-avatar.jpg"
}
```

## Error Responses

All endpoints return consistent error format:

```json
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid recovery answer",
    "details": "The provided recovery answer does not match"
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### Common Error Codes:
- `INVALID_CREDENTIALS`: Invalid authentication
- `WALLET_NOT_FOUND`: Wallet doesn't exist
- `WALLET_LOCKED`: Wallet needs to be unlocked
- `INSUFFICIENT_FUNDS`: Not enough balance for transaction
- `NETWORK_ERROR`: Blockchain network error
- `VALIDATION_ERROR`: Invalid request parameters

## Rate Limiting

- OAuth endpoints: 10 requests per minute per IP
- Transaction signing: 5 requests per minute per user
- Other endpoints: 100 requests per minute per user

## Security Notes

1. All private keys are split using Shamir Secret Sharing (3,2)
2. Recovery shards are encrypted with user's answer
3. Device shards are encrypted with device-specific keys
4. JWT tokens expire after 1 hour
5. Refresh tokens expire after 30 days
6. All sensitive operations require wallet session
7. WebAuthN support for biometric authentication
