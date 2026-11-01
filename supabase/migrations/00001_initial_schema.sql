-- ==============================================================================
-- Around Platform: Database Migration 00001 - Initial Schema, Constraints & PostGIS
-- ==============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA extensions;

-- 2. Enums
CREATE TYPE audience_type AS ENUM ('friends', 'public');
CREATE TYPE friendship_status AS ENUM ('pending', 'accepted', 'declined');
CREATE TYPE save_status AS ENUM ('want_to_go', 'been', 'favorite');
CREATE TYPE report_target AS ENUM ('post', 'place', 'profile');
CREATE TYPE report_status AS ENUM ('pending', 'reviewed', 'resolved');
CREATE TYPE notification_kind AS ENUM ('drop', 'save', 'follow', 'plan');

-- 3. Profiles Table (extends auth.users) with strict input validation constraints
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL CHECK (char_length(trim(username)) BETWEEN 2 AND 32 AND username ~ '^[a-zA-Z0-9_.-]+$'),
  full_name TEXT NOT NULL CHECK (char_length(trim(full_name)) BETWEEN 1 AND 80),
  avatar_url TEXT CHECK (avatar_url IS NULL OR char_length(avatar_url) <= 500),
  bio TEXT NOT NULL DEFAULT '' CHECK (char_length(bio) <= 300),
  neighborhood TEXT NOT NULL DEFAULT 'Mirabad' CHECK (char_length(trim(neighborhood)) BETWEEN 1 AND 80),
  hide_visits_history BOOLEAN NOT NULL DEFAULT TRUE,
  default_audience audience_type NOT NULL DEFAULT 'friends',
  discoverable_by_friends BOOLEAN NOT NULL DEFAULT TRUE,
  quiet_hours BOOLEAN NOT NULL DEFAULT FALSE,
  allow_friend_requests BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Friendships Table (Social Graph)
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status friendship_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_friendship UNIQUE (user_id, friend_id),
  CONSTRAINT no_self_friendship CHECK (user_id <> friend_id)
);

CREATE INDEX idx_friendships_user ON friendships(user_id, status);
CREATE INDEX idx_friendships_friend ON friendships(friend_id, status);

-- 5. Canonical Places Table (Own Place Database + PostGIS)
CREATE TABLE IF NOT EXISTS places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (char_length(trim(slug)) BETWEEN 2 AND 100),
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 1 AND 120),
  category TEXT NOT NULL CHECK (char_length(trim(category)) BETWEEN 1 AND 80),
  street_address TEXT NOT NULL CHECK (char_length(trim(street_address)) BETWEEN 1 AND 200),
  district TEXT NOT NULL DEFAULT 'Mirabad' CHECK (char_length(trim(district)) BETWEEN 1 AND 80),
  city TEXT NOT NULL DEFAULT 'Tashkent' CHECK (char_length(trim(city)) BETWEEN 1 AND 80),
  -- Geographic point: SRID 4326 (WGS 84 GPS standard: Longitude, Latitude)
  location GEOGRAPHY(Point, 4326) NOT NULL,
  price_tier TEXT NOT NULL DEFAULT '$$' CHECK (char_length(price_tier) <= 10),
  hours TEXT NOT NULL DEFAULT '8:00 AM – 10:00 PM' CHECK (char_length(hours) <= 100),
  status_line TEXT NOT NULL DEFAULT 'Open today' CHECK (char_length(status_line) <= 120),
  description TEXT NOT NULL DEFAULT '' CHECK (char_length(description) <= 600),
  hero_image_url TEXT CHECK (hero_image_url IS NULL OR char_length(hero_image_url) <= 500),
  rating_avg NUMERIC(2,1) NOT NULL DEFAULT 4.5 CHECK (rating_avg >= 1.0 AND rating_avg <= 5.0),
  rating_count INTEGER NOT NULL DEFAULT 0 CHECK (rating_count >= 0),
  tags TEXT[] NOT NULL DEFAULT '{}' CHECK (cardinality(tags) <= 15),
  photos TEXT[] NOT NULL DEFAULT '{}' CHECK (cardinality(photos) <= 20),
  -- External provider mapping (Google Places / Yandex MapKit cache-compliant ID)
  external_provider_source TEXT CHECK (external_provider_source IS NULL OR external_provider_source IN ('yandex', 'google', 'osm')),
  external_provider_id TEXT CHECK (external_provider_id IS NULL OR char_length(external_provider_id) <= 128),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Spatial & search indexes for sub-millisecond geographic proximity and tag searches
CREATE INDEX idx_places_spatial_location ON places USING GIST(location);
CREATE INDEX idx_places_category ON places(category);
CREATE INDEX idx_places_slug ON places(slug);
CREATE INDEX idx_places_tags ON places USING GIN(tags);

-- 6. Posts Table (Place Drops) with input validation and moderation quarantine fields
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL DEFAULT auth.uid() REFERENCES profiles(id) ON DELETE CASCADE,
  place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  note TEXT NOT NULL CHECK (char_length(trim(note)) BETWEEN 1 AND 500),
  rating SMALLINT CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5)),
  audience audience_type NOT NULL DEFAULT 'friends',
  size TEXT NOT NULL DEFAULT 'half' CHECK (size IN ('hero', 'half', 'wide', 'note')),
  tags TEXT[] NOT NULL DEFAULT '{}' CHECK (cardinality(tags) <= 10),
  saves_count INTEGER NOT NULL DEFAULT 0 CHECK (saves_count >= 0),
  likes_count INTEGER NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
  reports_count INTEGER NOT NULL DEFAULT 0 CHECK (reports_count >= 0),
  is_quarantined BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_author ON posts(author_id, created_at DESC);
CREATE INDEX idx_posts_place ON posts(place_id);
CREATE INDEX idx_posts_audience ON posts(audience) WHERE is_quarantined = FALSE;
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- 7. Post Media Table with strict MIME type and dimension validation
CREATE TABLE IF NOT EXISTS post_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL CHECK (char_length(trim(storage_path)) BETWEEN 1 AND 500),
  media_url TEXT NOT NULL CHECK (char_length(trim(media_url)) BETWEEN 1 AND 500),
  thumbnail_url TEXT CHECK (thumbnail_url IS NULL OR char_length(thumbnail_url) <= 500),
  media_type TEXT NOT NULL DEFAULT 'image/jpeg' CHECK (media_type IN ('image/jpeg', 'image/png', 'image/webp')),
  width INTEGER CHECK (width IS NULL OR (width > 0 AND width <= 8192)),
  height INTEGER CHECK (height IS NULL OR (height > 0 AND height <= 8192)),
  is_primary BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_post_media_post ON post_media(post_id);

-- 8. Saved Places (Shortlists & Statuses)
CREATE TABLE IF NOT EXISTS saved_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES profiles(id) ON DELETE CASCADE,
  place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  status save_status NOT NULL DEFAULT 'want_to_go',
  notes TEXT CHECK (notes IS NULL OR char_length(notes) <= 300),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_saved_place UNIQUE (user_id, place_id)
);

CREATE INDEX idx_saved_places_user ON saved_places(user_id, status);
CREATE INDEX idx_saved_places_place ON saved_places(place_id);

-- 9. Friend Plans Table (Collaborative Plans at Venues)
CREATE TABLE IF NOT EXISTS friend_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL DEFAULT auth.uid() REFERENCES profiles(id) ON DELETE CASCADE,
  place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  schedule_time TEXT NOT NULL CHECK (char_length(trim(schedule_time)) BETWEEN 1 AND 80),
  note TEXT NOT NULL DEFAULT '' CHECK (char_length(note) <= 240),
  attendee_ids UUID[] NOT NULL DEFAULT '{}' CHECK (cardinality(attendee_ids) <= 25),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_friend_plans_creator ON friend_plans(creator_id);
CREATE INDEX idx_friend_plans_place ON friend_plans(place_id);

-- 10. Activity Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  actor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  kind notification_kind NOT NULL,
  place_id UUID REFERENCES places(id) ON DELETE CASCADE,
  message TEXT NOT NULL CHECK (char_length(trim(message)) BETWEEN 1 AND 240),
  unread BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id, unread, created_at DESC);

-- 11. User Blocks (Safety)
CREATE TABLE IF NOT EXISTS blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL DEFAULT auth.uid() REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id),
  CONSTRAINT no_self_block CHECK (blocker_id <> blocked_id)
);

CREATE INDEX idx_blocks_blocker ON blocks(blocker_id);
CREATE INDEX idx_blocks_blocked ON blocks(blocked_id);

-- 12. Content & Account Reports (Moderation)
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL DEFAULT auth.uid() REFERENCES profiles(id) ON DELETE CASCADE,
  target_type report_target NOT NULL,
  target_id TEXT NOT NULL CHECK (char_length(trim(target_id)) BETWEEN 1 AND 128),
  reason TEXT NOT NULL CHECK (char_length(trim(reason)) BETWEEN 3 AND 200),
  details TEXT CHECK (details IS NULL OR char_length(details) <= 1000),
  status report_status NOT NULL DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_reporter_target UNIQUE (reporter_id, target_type, target_id)
);

CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_target ON reports(target_type, target_id);
