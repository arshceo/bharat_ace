-- Supabase Database Schema for Bharat Ace App
-- Run these commands in your Supabase SQL Editor

-- 1. Create users table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    school TEXT,
    board TEXT,
    grade TEXT,
    enrolled_subjects TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    xp INTEGER DEFAULT 0,
    coins INTEGER DEFAULT 0,
    daily_streak INTEGER DEFAULT 0,
    is_premium BOOLEAN DEFAULT FALSE,
    avatar TEXT,
    bio TEXT,
    study_goal TEXT,
    contributions_count INTEGER DEFAULT 0,
    study_buddies_count INTEGER DEFAULT 0,
    exam_date TIMESTAMPTZ,
    mst_date TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create user_creations table
CREATE TABLE IF NOT EXISTS user_creations (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('image', 'video')),
    download_url TEXT NOT NULL,
    thumbnail_url TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create bookmarks table (for future use)
CREATE TABLE IF NOT EXISTS bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_id TEXT NOT NULL REFERENCES user_creations(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, content_id)
);

-- 4. Create comments table for reels
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reel_id TEXT NOT NULL REFERENCES user_creations(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    likes INTEGER DEFAULT 0,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE, -- For replies
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create comment_likes table
CREATE TABLE IF NOT EXISTS comment_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(comment_id, user_id)
);

-- 6. Create follows table for user following
CREATE TABLE IF NOT EXISTS follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK(follower_id != following_id)
);

-- 7. Create reel_likes table
CREATE TABLE IF NOT EXISTS reel_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reel_id TEXT NOT NULL REFERENCES user_creations(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(reel_id, user_id)
);

-- 8. Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('profile-images', 'profile-images', true),
    ('user-content', 'user-content', true)
ON CONFLICT (id) DO NOTHING;

-- 9. Drop existing storage policies to recreate them
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Profile images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own content" ON storage.objects;
DROP POLICY IF EXISTS "User content is publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own content" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own content" ON storage.objects;

-- 10. Create more permissive storage policies for profile-images bucket
CREATE POLICY "Allow public upload to profile-images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'profile-images');

CREATE POLICY "Profile images are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-images');

CREATE POLICY "Allow public update to profile-images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'profile-images');

CREATE POLICY "Allow public delete from profile-images" ON storage.objects
    FOR DELETE USING (bucket_id = 'profile-images');

-- 11. Create more permissive storage policies for user-content bucket
CREATE POLICY "Allow public upload to user-content" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'user-content');

CREATE POLICY "User content is publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'user-content');

CREATE POLICY "Allow public update to user-content" ON storage.objects
    FOR UPDATE USING (bucket_id = 'user-content');

CREATE POLICY "Allow public delete from user-content" ON storage.objects
    FOR DELETE USING (bucket_id = 'user-content');

-- 12. Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_creations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- 13. Create Row Level Security policies for users table
DROP POLICY IF EXISTS "Users can view all profiles" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;

CREATE POLICY "Users can view all profiles" ON users
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (true);

-- 14. Create Row Level Security policies for user_creations table
DROP POLICY IF EXISTS "Anyone can view user creations" ON user_creations;
DROP POLICY IF EXISTS "Users can insert their own creations" ON user_creations;
DROP POLICY IF EXISTS "Users can update their own creations" ON user_creations;
DROP POLICY IF EXISTS "Users can delete their own creations" ON user_creations;

CREATE POLICY "Anyone can view user creations" ON user_creations
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own creations" ON user_creations
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own creations" ON user_creations
    FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own creations" ON user_creations
    FOR DELETE USING (true);

-- 15. Create Row Level Security policies for bookmarks table
DROP POLICY IF EXISTS "Users can view their own bookmarks" ON bookmarks;
DROP POLICY IF EXISTS "Users can create their own bookmarks" ON bookmarks;
DROP POLICY IF EXISTS "Users can delete their own bookmarks" ON bookmarks;

CREATE POLICY "Users can view their own bookmarks" ON bookmarks
    FOR SELECT USING (true);

CREATE POLICY "Users can create their own bookmarks" ON bookmarks
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can delete their own bookmarks" ON bookmarks
    FOR DELETE USING (true);

-- 16. Create Row Level Security policies for comments table
DROP POLICY IF EXISTS "Users can view all comments" ON comments;
DROP POLICY IF EXISTS "Users can insert their own comments" ON comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;

CREATE POLICY "Users can view all comments" ON comments
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own comments" ON comments
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own comments" ON comments
    FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own comments" ON comments
    FOR DELETE USING (true);

-- 17. Create Row Level Security policies for comment_likes table
DROP POLICY IF EXISTS "Users can like any comment" ON comment_likes;
DROP POLICY IF EXISTS "Users can unlike any comment" ON comment_likes;

CREATE POLICY "Users can like any comment" ON comment_likes
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can unlike any comment" ON comment_likes
    FOR DELETE USING (true);

-- 18. Create Row Level Security policies for follows table
DROP POLICY IF EXISTS "Users can follow any user" ON follows;
DROP POLICY IF EXISTS "Users can unfollow any user" ON follows;

CREATE POLICY "Users can follow any user" ON follows
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can unfollow any user" ON follows
    FOR DELETE USING (true);

-- 19. Create Row Level Security policies for reel_likes table
DROP POLICY IF EXISTS "Users can like any reel" ON reel_likes;
DROP POLICY IF EXISTS "Users can unlike any reel" ON reel_likes;

CREATE POLICY "Users can like any reel" ON reel_likes
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can unlike any reel" ON reel_likes
    FOR DELETE USING (true);

-- 20. Create functions for incrementing views and likes
CREATE OR REPLACE FUNCTION increment_views(content_id TEXT)
RETURNS void AS $$
BEGIN
    UPDATE user_creations 
    SET views = views + 1, updated_at = NOW()
    WHERE id = content_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_likes(content_id TEXT)
RETURNS void AS $$
BEGIN
    UPDATE user_creations 
    SET likes = likes + 1, updated_at = NOW()
    WHERE id = content_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_likes(content_id TEXT)
RETURNS void AS $$
BEGIN
    UPDATE user_creations 
    SET likes = GREATEST(likes - 1, 0), updated_at = NOW()
    WHERE id = content_id;
END;
$$ LANGUAGE plpgsql;

-- SQL Functions for atomic operations
-- Function to increment reel likes count
CREATE OR REPLACE FUNCTION increment_reel_likes(reel_id TEXT)
RETURNS void AS $$
BEGIN
    UPDATE user_creations 
    SET likes = likes + 1 
    WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement reel likes count
CREATE OR REPLACE FUNCTION decrement_reel_likes(reel_id TEXT)
RETURNS void AS $$
BEGIN
    UPDATE user_creations 
    SET likes = GREATEST(likes - 1, 0)
    WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql;

-- Function to increment study buddies count
CREATE OR REPLACE FUNCTION increment_study_buddies(user_id TEXT)
RETURNS void AS $$
BEGIN
    UPDATE users 
    SET study_buddies_count = study_buddies_count + 1 
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement study buddies count
CREATE OR REPLACE FUNCTION decrement_study_buddies(user_id TEXT)
RETURNS void AS $$
BEGIN
    UPDATE users 
    SET study_buddies_count = GREATEST(study_buddies_count - 1, 0)
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- 21. Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_creations_updated_at ON user_creations;
CREATE TRIGGER update_user_creations_updated_at BEFORE UPDATE ON user_creations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_comments_updated_at ON comments;
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 22. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_creations_user_id ON user_creations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_creations_timestamp ON user_creations(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_user_creations_type ON user_creations(type);
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id ON bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_comments_reel_id ON comments(reel_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comment_likes_comment_id ON comment_likes(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_likes_user_id ON comment_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_reel_likes_reel_id ON reel_likes(reel_id);
CREATE INDEX IF NOT EXISTS idx_reel_likes_user_id ON reel_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_creations_type ON user_creations(type);
CREATE INDEX IF NOT EXISTS idx_user_creations_timestamp ON user_creations(timestamp DESC);
