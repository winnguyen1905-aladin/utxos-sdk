-- Migration 001: Simplified Cardano Social Wallet Schema
-- Focus: Social login + Cardano transaction signing only

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table - social account information only
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    provider VARCHAR(50) NOT NULL,
    provider_id VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    username VARCHAR(100),
    
    CONSTRAINT users_provider_unique UNIQUE(provider, provider_id),
    CONSTRAINT users_valid_provider CHECK (provider IN ('google', 'discord', 'twitter', 'apple'))
);

-- Wallets table - Cardano only with encrypted shards
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    auth_shard TEXT NOT NULL,
    recovery_shard TEXT NOT NULL,
    recovery_question TEXT,
    
    -- Cardano only - public key hashes for address generation
    cardano_pub_key_hash VARCHAR(64) NOT NULL,
    cardano_stake_credential_hash VARCHAR(64) NOT NULL,
    
    network_id INTEGER DEFAULT 0 CHECK (network_id IN (0, 1)),
    
    CONSTRAINT wallets_user_unique UNIQUE(user_id)
);

-- Signing sessions - simple session management for transaction signing
CREATE TABLE signing_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    session_token VARCHAR(255) NOT NULL UNIQUE,
    
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