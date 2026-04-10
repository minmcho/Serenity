"""
VitalPath AI - Database Schema for Supabase PostgreSQL

Run this SQL in your Supabase SQL Editor to create all required tables.
"""

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Wellness Profiles Table
CREATE TABLE IF NOT EXISTS wellness_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    dietary_restrictions TEXT[] DEFAULT '{}',
    preferences TEXT[] DEFAULT '{}',
    goals TEXT[] DEFAULT '{}',
    activity_level VARCHAR(50) DEFAULT 'moderate',
    languages TEXT[] DEFAULT '{"en"}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Wellness Sessions Table
CREATE TABLE IF NOT EXISTS wellness_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_type VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    mood_before INTEGER CHECK (mood_before >= 1 AND mood_before <= 10),
    mood_after INTEGER CHECK (mood_after >= 1 AND mood_after <= 10),
    duration_seconds INTEGER,
    streak_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Wearable Connections Table
CREATE TABLE IF NOT EXISTS wearable_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_type VARCHAR(50) NOT NULL,
    is_connected BOOLEAN DEFAULT TRUE,
    steps_today INTEGER DEFAULT 0,
    heart_rate_avg FLOAT DEFAULT 0.0,
    calories_burned INTEGER DEFAULT 0,
    sleep_hours FLOAT,
    last_synced TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_type)
);

-- Video Analysis Tasks Table
CREATE TABLE IF NOT EXISTS video_analysis_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    analysis_type VARCHAR(50) NOT NULL, -- 'meal' or 'exercise'
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
    result JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Crisis Events Table (hashed, no PHI)
CREATE TABLE IF NOT EXISTS crisis_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_hash VARCHAR(64) NOT NULL, -- SHA256 hash of user_id
    severity VARCHAR(50) NOT NULL,
    region VARCHAR(10) DEFAULT 'US',
    keywords_detected TEXT[] DEFAULT '{}',
    helpline_shown BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_wellness_sessions_user_id ON wellness_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_wellness_sessions_created_at ON wellness_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wearable_connections_user_id ON wearable_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_video_tasks_user_id ON video_analysis_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_video_tasks_status ON video_analysis_tasks(status);
CREATE INDEX IF NOT EXISTS idx_crisis_events_user_hash ON crisis_events(user_hash);
CREATE INDEX IF NOT EXISTS idx_crisis_events_created_at ON crisis_events(created_at DESC);

-- Row Level Security (RLS) Policies
ALTER TABLE wellness_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellness_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE wearable_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_analysis_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE crisis_events ENABLE ROW LEVEL SECURITY;

-- Wellness Profiles Policies
CREATE POLICY "Users can view their own profile"
    ON wellness_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile"
    ON wellness_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
    ON wellness_profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- Wellness Sessions Policies
CREATE POLICY "Users can view their own sessions"
    ON wellness_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sessions"
    ON wellness_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Wearable Connections Policies
CREATE POLICY "Users can view their own wearable data"
    ON wearable_connections FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own wearable connections"
    ON wearable_connections FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Video Analysis Tasks Policies
CREATE POLICY "Users can view their own video tasks"
    ON video_analysis_tasks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own video tasks"
    ON video_analysis_tasks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Crisis Events Policies (service role only for inserts)
CREATE POLICY "Service role can insert crisis events"
    ON crisis_events FOR INSERT
    TO service_role
    WITH CHECK (true);

CREATE POLICY "Service role can view crisis events"
    ON crisis_events FOR SELECT
    TO service_role
    USING (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_wellness_profiles_updated_at
    BEFORE UPDATE ON wellness_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wellness_sessions_updated_at
    BEFORE UPDATE ON wellness_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wearable_connections_updated_at
    BEFORE UPDATE ON wearable_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Storage Bucket for Videos (run in Supabase Storage UI or via API)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('videos', 'videos', false);

-- Storage Policies for Videos
-- CREATE POLICY "Users can upload their own videos"
--     ON storage.objects FOR INSERT
--     WITH CHECK (bucket_id = 'videos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Users can view their own videos"
--     ON storage.objects FOR SELECT
--     USING (bucket_id = 'videos' AND auth.uid()::text = (storage.foldername(name))[1]);
