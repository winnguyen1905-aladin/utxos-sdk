-- Simplified Database Schema for Cardano Social Wallet
-- Focus: Social login + Cardano transaction signing only

-- Users table - stores social account information
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Social authentication fields
    provider VARCHAR(50) NOT NULL, -- 'google', 'discord', 'twitter', 'apple'
    provider_id VARCHAR(255) NOT NULL, -- Unique ID from social provider
    email VARCHAR(255),
    username VARCHAR(100),
    
    -- Constraints
    UNIQUE(provider, provider_id), -- One user per social account
    CONSTRAINT valid_provider CHECK (provider IN ('google', 'discord', 'twitter', 'apple'))
);

-- Wallets table - stores encrypted wallet shards and Cardano keys only
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Foreign key to user
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Encrypted key shards (NEVER store complete private key)
    auth_shard TEXT NOT NULL, -- Server-side shard, encrypted
    recovery_shard TEXT NOT NULL, -- Recovery shard, encrypted with user's answer
    recovery_question TEXT, -- User's recovery question for reference
    
    -- Cardano only - public key hashes for address generation
    cardano_pub_key_hash VARCHAR(64) NOT NULL,
    cardano_stake_credential_hash VARCHAR(64) NOT NULL,
    
    -- Network preference
    network_id INTEGER DEFAULT 0 CHECK (network_id IN (0, 1)), -- 0=testnet, 1=mainnet
    
    -- Constraints
    UNIQUE(user_id) -- One wallet per user
);

-- Signing sessions - simple session management for transaction signing
CREATE TABLE signing_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- User reference
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Simple session token for signing transactions
    session_token VARCHAR(255) NOT NULL UNIQUE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE
);

-- Indexes for performance
CREATE INDEX idx_users_provider_id ON users(provider, provider_id);
CREATE INDEX idx_wallets_user_id ON wallets(user_id);
CREATE INDEX idx_signing_sessions_user_id ON signing_sessions(user_id);
CREATE INDEX idx_signing_sessions_token ON signing_sessions(session_token);
CREATE INDEX idx_signing_sessions_expires_at ON signing_sessions(expires_at);

-- Clean up expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
    UPDATE signing_sessions 
    SET is_active = false 
    WHERE expires_at < NOW() AND is_active = true;
END;
$$ LANGUAGE plpgsql;
