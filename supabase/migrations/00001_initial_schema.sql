-- ==============================================================================
-- Around Platform: Database Migration 00001 - Initial Schema & PostGIS
-- ==============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. Enums
CREATE TYPE audience_type AS ENUM ('friends', 'public');
CREATE TYPE friendship_status AS ENUM ('pending', 'accepted', 'declined');
CREATE TYPE save_status AS ENUM ('want_to_go', 'been', 'favorite');
CREATE TYPE report_target AS ENUM ('post', 'place', 'profile');
CREATE TYPE report_status AS ENUM ('pending', 'reviewed', 'resolved');

-- 3. Profiles Table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT DEFAULT '',
  neighborhood TEXT DEFAULT 'Barlow Hill',
  hide_visits_history BOOLEAN DEFAULT TRUE,
  default_audience audience_type DEFAULT 'friends',
  quiet_hours BOOLEAN DEFAULT FALSE,
  allow_friend_requests BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Friendships Table (Social Graph)
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status friendship_status DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_friendship UNIQUE (user_id, friend_id),
  CONSTRAINT no_self_friendship CHECK (user_id <> friend_id)
);

CREATE INDEX idx_friendships_user ON friendships(user_id, status);
CREATE INDEX idx_friendships_friend ON friendships(friend_id, status);

-- 5. Canonical Places Table (Own Place Database + PostGIS)
CREATE TABLE IF NOT EXISTS places (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  street_address TEXT NOT NULL,
  district TEXT NOT NULL DEFAULT 'Barlow Hill',
  city TEXT NOT NULL DEFAULT 'Tashkent',
  -- Geographic point: SRID 4326 (WGS 84 GPS standard: Longitude, Latitude)
  location GEOGRAPHY(Point, 4326) NOT NULL,
  price_tier TEXT DEFAULT '€€',
  hours TEXT DEFAULT '8:00 AM – 10:00 PM',
  status_line TEXT DEFAULT 'Open today',
  description TEXT DEFAULT '',
  hero_image_url TEXT,
  rating_avg NUMERIC(2,1) DEFAULT 4.5,
  rating_count INTEGER DEFAULT 0,
  tags TEXT[] DEFAULT '{}',
  -- External provider mapping (Google Places / Yandex MapKit cache-compliant ID)
  external_provider_source TEXT, -- 'yandex', 'google', 'osm'
  external_provider_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spatial index for sub-millisecond geographic proximity searches
CREATE INDEX idx_places_spatial_location ON places USING GIST(location);
CREATE INDEX idx_places_category ON places(category);
CREATE INDEX idx_places_slug ON places(slug);

-- 6. Posts Table (Place Drops)
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  note TEXT NOT NULL,
  rating SMALLINT CHECK (rating >= 1 AND rating <= 5),
  audience audience_type NOT NULL DEFAULT 'friends',
  tags TEXT[] DEFAULT '{}',
  saves_count INTEGER DEFAULT 0,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_place ON posts(place_id);
CREATE INDEX idx_posts_audience ON posts(audience);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- 7. Post Media Table
CREATE TABLE IF NOT EXISTS post_media (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  media_type TEXT DEFAULT 'image/jpeg',
  width INTEGER,
  height INTEGER,
  is_primary BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_post_media_post ON post_media(post_id);

-- 8. Saved Places (Shortlists & Plans)
CREATE TABLE IF NOT EXISTS saved_places (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  status save_status DEFAULT 'want_to_go',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_saved_place UNIQUE (user_id, place_id)
);

CREATE INDEX idx_saved_places_user ON saved_places(user_id);
CREATE INDEX idx_saved_places_place ON saved_places(place_id);

-- 9. User Blocks (Safety)
CREATE TABLE IF NOT EXISTS blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id),
  CONSTRAINT no_self_block CHECK (blocker_id <> blocked_id)
);

CREATE INDEX idx_blocks_blocker ON blocks(blocker_id);
CREATE INDEX idx_blocks_blocked ON blocks(blocked_id);

-- 10. Content & Account Reports (Moderation)
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type report_target NOT NULL,
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  details TEXT,
  status report_status DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reports_status ON reports(status);
