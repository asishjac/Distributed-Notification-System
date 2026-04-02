-- Create User Preferences Table
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE NOT NULL,
    email_enabled BOOLEAN DEFAULT true,
    sms_enabled BOOLEAN DEFAULT false,
    push_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast user lookups during routing
CREATE INDEX IF NOT EXISTS idx_user_prefs_userid ON user_preferences(user_id);
