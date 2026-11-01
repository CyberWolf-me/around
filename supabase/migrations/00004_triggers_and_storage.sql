-- ==============================================================================
-- Around Platform: Database Migration 00004 - Rate Limits, Quarantine, Triggers & Storage
-- ==============================================================================

-- 1. Automatic Profile Creation Trigger on Supabase Auth Signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url, neighborhood)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      SPLIT_PART(NEW.email, '@', 1) || '_' || SUBSTR(NEW.id::text, 1, 4)
    ),
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1), 'Explorer'),
    NEW.raw_user_meta_data->>'avatar_url',
    COALESCE(NEW.raw_user_meta_data->>'neighborhood', 'Mirabad')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Rate-Limiting & Abuse Prevention Triggers (SEC-08 Remediation)
-- Prevent any single user from creating more than 10 drops within a 5-minute window
CREATE OR REPLACE FUNCTION public.enforce_post_rate_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  recent_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO recent_count
  FROM public.posts
  WHERE author_id = NEW.author_id
    AND created_at > NOW() - INTERVAL '5 minutes';

  IF recent_count >= 10 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 10 drops per 5 minutes allowed.'
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_post_rate_limit ON public.posts;
CREATE TRIGGER trg_enforce_post_rate_limit
  BEFORE INSERT ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.enforce_post_rate_limit();

-- Prevent report flooding (max 10 reports per 5 minutes per reporter)
CREATE OR REPLACE FUNCTION public.enforce_report_rate_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  recent_reports INTEGER;
BEGIN
  SELECT COUNT(*) INTO recent_reports
  FROM public.reports
  WHERE reporter_id = NEW.reporter_id
    AND created_at > NOW() - INTERVAL '5 minutes';

  IF recent_reports >= 10 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 10 moderation reports per 5 minutes allowed.'
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_report_rate_limit ON public.reports;
CREATE TRIGGER trg_enforce_report_rate_limit
  BEFORE INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.enforce_report_rate_limit();

-- 3. Automated 3-Report Quarantine Trigger (PRIVACY_AND_SAFETY_GOVERNANCE.md Compliance)
-- Any drop receiving 3+ unique user reports is automatically quarantined from feeds
CREATE OR REPLACE FUNCTION public.handle_post_report_quarantine()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  unique_reports INTEGER;
BEGIN
  IF NEW.target_type = 'post' THEN
    SELECT COUNT(DISTINCT reporter_id) INTO unique_reports
    FROM public.reports
    WHERE target_type = 'post'
      AND target_id = NEW.target_id;

    UPDATE public.posts
    SET
      reports_count = unique_reports,
      is_quarantined = (unique_reports >= 3),
      updated_at = NOW()
    WHERE id::text = NEW.target_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_quarantine_post ON public.reports;
CREATE TRIGGER trg_auto_quarantine_post
  AFTER INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.handle_post_report_quarantine();

-- 4. Trigger to Recalculate Canonical Place Rating Avg & Count on Public Post Changes
CREATE OR REPLACE FUNCTION public.recalculate_place_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_place_id UUID;
BEGIN
  target_place_id := COALESCE(NEW.place_id, OLD.place_id);
  UPDATE public.places
  SET
    rating_avg = COALESCE(
      (SELECT ROUND(AVG(rating)::numeric, 1) FROM public.posts WHERE place_id = target_place_id AND rating IS NOT NULL AND audience = 'public' AND is_quarantined = FALSE),
      rating_avg
    ),
    rating_count = (SELECT COUNT(*) FROM public.posts WHERE place_id = target_place_id AND rating IS NOT NULL AND audience = 'public' AND is_quarantined = FALSE),
    updated_at = NOW()
  WHERE id = target_place_id;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_posts_rating_sync ON public.posts;
CREATE TRIGGER trg_posts_rating_sync
  AFTER INSERT OR UPDATE OR DELETE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.recalculate_place_rating();

-- 5. Trigger to Sync Post Saves Counter when a Venue is Saved/Unsaved
CREATE OR REPLACE FUNCTION public.sync_place_saves_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_place_id UUID;
  total_saves INTEGER;
BEGIN
  target_place_id := COALESCE(NEW.place_id, OLD.place_id);
  SELECT COUNT(*) INTO total_saves FROM public.saved_places WHERE place_id = target_place_id;
  UPDATE public.posts
  SET saves_count = total_saves
  WHERE place_id = target_place_id;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_saved_places_count_sync ON public.saved_places;
CREATE TRIGGER trg_saved_places_count_sync
  AFTER INSERT OR DELETE ON public.saved_places
  FOR EACH ROW EXECUTE FUNCTION public.sync_place_saves_count();

-- 6. Storage Bucket for Drop Media ('post-media')
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-media',
  'post-media',
  true,
  5242880, -- 5 MB max per photo
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies (Restricted to authenticated users)
CREATE POLICY "post_media_storage_auth_read"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'post-media');

CREATE POLICY "post_media_storage_auth_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'post-media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "post_media_storage_owner_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'post-media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 7. Seed Canonical Tashkent Venues into Places Table
INSERT INTO public.places (id, slug, name, category, street_address, district, city, location, price_tier, hours, status_line, description, hero_image_url, rating_avg, rating_count, tags, photos)
VALUES
  (
    '11111111-1111-4111-8111-111111111101',
    'breadly-bakery-cafe',
    'Breadly Bakery & Café',
    'Bakery · Specialty Café',
    '24 Taras Shevchenko Street',
    'Mirabad',
    'Tashkent',
    ST_SetSRID(ST_MakePoint(69.2748, 41.2996), 4326)::geography,
    '$$',
    '8:00 AM – 10:00 PM',
    'Open today · Fresh bake at 8am',
    'Sun-drenched courtyard bakery in Mirabad. Artisan sourdough baked fresh daily, lavender matcha, delicate pastries, and Tashkent’s best brunch veranda.',
    'assets/bakery-counter.jpg',
    4.8,
    342,
    ARRAY['artisan sourdough', 'courtyard', 'specialty coffee', 'quiet mornings'],
    ARRAY['assets/bakery-counter.jpg', 'assets/cafe-light.jpg', 'assets/pastries.jpg']
  ),
  (
    '11111111-1111-4111-8111-111111111102',
    'bnb-coffee-house',
    'B&B Coffee House',
    'Study Café · Roastery',
    '24 Shota Rustaveli Street',
    'Yakkasaray',
    'Tashkent',
    ST_SetSRID(ST_MakePoint(69.2619, 41.2918), 4326)::geography,
    '$',
    '8:00 AM – 11:00 PM',
    'Closes 11pm · Fast Wi-Fi',
    'The definitive Tashkent student and remote-work haven. Sockets at every wooden booth, single-origin pour-overs, Basque cheesecake, and focused vibe.',
    'assets/study-desk.jpg',
    4.6,
    512,
    ARRAY['power outlets', 'study-friendly', 'chemex', 'long stays'],
    ARRAY['assets/study-table.jpg', 'assets/cafe-light.jpg', 'assets/study-desk.jpg']
  ),
  (
    '11111111-1111-4111-8111-111111111103',
    'ecorn-patisserie',
    'Ecorn Patisserie',
    'French Patisserie · Bistro',
    '32 Amir Timur Avenue',
    'Yunusabad',
    'Tashkent',
    ST_SetSRID(ST_MakePoint(69.2825, 41.3175), 4326)::geography,
    '$$$',
    '9:00 AM – 10:00 PM',
    'Closes 10pm · Terrace open',
    'Refined Parisian viennoiserie overlooking Amir Timur Avenue. Flaky pistachio pain au chocolat, raspberry mille-feuille, and quiet second-floor terrace.',
    'assets/patisserie.jpg',
    4.7,
    228,
    ARRAY['pistachio eclair', 'terrace', 'date spot', 'french press'],
    ARRAY['assets/patisserie.jpg', 'assets/pastries.jpg', 'assets/storefront.jpg']
  ),
  (
    '11111111-1111-4111-8111-111111111104',
    'tims-coffee-roastery',
    'Tim’s Coffee & Roastery',
    'Specialty Roastery · Espresso Bar',
    '40 Taras Shevchenko Street',
    'Mirabad',
    'Tashkent',
    ST_SetSRID(ST_MakePoint(69.2778, 41.2975), 4326)::geography,
    '$$',
    '8:00 AM – 11:00 PM',
    'Open today · Roasting Tuesdays',
    'Tashkent’s third-wave pioneer. Micro-roasted Ethiopian and Colombian beans, calibrated espresso flights, communal wooden benches, and tech founders crowd.',
    'assets/cafe-light.jpg',
    4.9,
    419,
    ARRAY['single origin', 'v60 pour-over', 'tech crowd', 'roastery'],
    ARRAY['assets/cafe-light.jpg', 'assets/records-crates.jpg', 'assets/cafe-bw.jpg']
  ),
  (
    '11111111-1111-4111-8111-111111111105',
    'chorsu-national-food',
    'Chorsu Milliy Taomlar',
    'Uzbek Cuisine · Open Kitchen',
    'Beruni Avenue, Chorsu Old City',
    'Shaykhontohur',
    'Tashkent',
    ST_SetSRID(ST_MakePoint(69.2344, 41.3268), 4326)::geography,
    '$',
    '10:00 AM – 9:00 PM',
    'Wedding Plov ready at 11am',
    'The monumental culinary soul of Old Tashkent. Giant steaming bronze kazans of saffron-scented Wedding Osh plov, crisp tandir somsa, and lemon tea under azure domes.',
    'assets/street.jpg',
    4.9,
    880,
    ARRAY['wedding plov', 'tandir somsa', 'kazan cooking', 'authentic', 'ramen'],
    ARRAY['assets/street.jpg', 'assets/ramen-bowl.jpg', 'assets/storefront.jpg']
  ),
  (
    '11111111-1111-4111-8111-111111111106',
    'central-park-tashkent',
    'Central Park (Mirzo Ulugbek)',
    'Park · Green Promenade',
    '21 Movaraunnahr Street',
    'Mirzo Ulugbek',
    'Tashkent',
    ST_SetSRID(ST_MakePoint(69.2931, 41.3142), 4326)::geography,
    'Free',
    '6:00 AM – 11:00 PM',
    'Open · Sunset promenade',
    'Centuries-old shaded sycamores, swans paddling along the lake, rollerblading paths, and evening matcha kiosks. Tashkent’s premier outdoor community space.',
    'assets/window-girl.jpg',
    4.7,
    654,
    ARRAY['shaded walks', 'evening strolls', 'lake', 'matcha kiosk'],
    ARRAY['assets/window-girl.jpg', 'assets/cafe-bw.jpg', 'assets/street.jpg']
  ),
  (
    '11111111-1111-4111-8111-111111111107',
    'steam-bar-lounge',
    'Steam Bar & Lounge',
    'Cocktail Lounge · Wine Bar · Vinyl Records',
    '29 Nukus Street',
    'Mirabad',
    'Tashkent',
    ST_SetSRID(ST_MakePoint(69.2694, 41.2942), 4326)::geography,
    '$$$',
    '6:00 PM – 2:00 AM',
    'Opens 6pm · DJ from 9pm',
    'Industrial steampunk aesthetics, curated craft cocktails infused with local pomegranate and mountain herbs, and resident DJs playing analog vinyl sets.',
    'assets/wine-wide.jpg',
    4.6,
    310,
    ARRAY['craft cocktails', 'vinyl DJ', 'late night', 'date spot', 'records', 'wine bar'],
    ARRAY['assets/wine-wide.jpg', 'assets/wine-tall.jpg', 'assets/records.jpg']
  ),
  (
    '11111111-1111-4111-8111-111111111108',
    'kitobxon-book-cafe',
    'Kitobxon Book Café',
    'Bookshop · Literary Café',
    '11 Alisher Navoi Avenue',
    'Yunusabad',
    'Tashkent',
    ST_SetSRID(ST_MakePoint(69.2558, 41.3182), 4326)::geography,
    '$',
    '9:00 AM – 9:00 PM',
    'Open today · Quiet reading zone',
    'Three-room independent bookstore café near Navoi Theatre. Floor-to-ceiling shelves of Uzbek and world classics, plush armchairs, and slow Aeropress coffee.',
    'assets/bookshop.jpg',
    4.8,
    195,
    ARRAY['bookstore', 'bookshop', 'quiet nooks', 'aeropress', 'reading'],
    ARRAY['assets/bookshop.jpg', 'assets/bookshop-tall.jpg', 'assets/storefront.jpg']
  ),
  (
    '11111111-1111-4111-8111-111111111109',
    'broadway-sayilgoh',
    'Broadway (Sayilgoh Street)',
    'Pedestrian Promenade · Arts',
    'Sayilgoh Street, Amir Timur Square',
    'Yunusabad',
    'Tashkent',
    ST_SetSRID(ST_MakePoint(69.2772, 41.3129), 4326)::geography,
    '$',
    'Open 24 hours',
    'Lively atmosphere tonight',
    'Tashkent’s legendary pedestrian avenue connecting Mustaqillik Square and Amir Timur Square. Portrait painters, antique vendors, street performers, and ice cream stands.',
    'assets/storefront.jpg',
    4.5,
    780,
    ARRAY['street artists', 'souvenirs', 'night stroll', 'bustling'],
    ARRAY['assets/storefront.jpg', 'assets/street.jpg', 'assets/ramen-bowl.jpg']
  )
ON CONFLICT (slug) DO NOTHING;
