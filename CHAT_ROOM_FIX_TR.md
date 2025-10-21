# Chat Room Oluşturulmuyor Sorunu - Çözüm

## 🔍 Sorun Tespiti

**Durum:** İki taraf da match'i accept ettiğinde "Chat Room Ready!" mesajı görünüyor ama chat linki/odası yok, sadece "Loading chat room..." yazıyor.

**Sebep:** Muhtemelen aşağıdaki sorunlardan biri:

1. ✅ **Kod doğru** - `ensureChatRoom()` fonksiyonu her iki taraf accept ettiğinde çağrılıyor
2. ❌ **Database tabloları eksik** - Production Supabase'de `chat_rooms`, `chat_participants`, `chat_messages` tabloları oluşturulmamış
3. ❌ **RLS policies eksik** - Tablolar var ama erişim politikaları yapılmamış
4. ❌ **Frontend fetch hatası** - Chat room ID'si oluşturulmuş ama frontend çekemiyor

---

## 🛠️ Çözüm Adımları

### Adım 1: Database Tablolarını Kontrol Et

**Supabase Dashboard** → **SQL Editor**'da şunu çalıştır:

```sql
-- Tabloları kontrol et
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('chat_rooms', 'chat_participants', 'chat_messages');
```

**Beklenen sonuç:** 3 satır dönmeli (chat_rooms, chat_participants, chat_messages)

**Eğer 0 satır dönerse:** Tablolar oluşturulmamış, Adım 2'ye geç.

---

### Adım 2: Migration'ları Uygula (Production'da)

**Supabase Dashboard** → **SQL Editor** → **New Query**

Aşağıdaki migration'ı kopyala-yapıştır ve **Run** butonuna bas:

```sql
-- ============================================================================
-- CHAT ROOMS MIGRATION - PRODUCTION
-- ============================================================================

-- 1. chat_rooms tablosu
CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  first_join_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  ttl_seconds INTEGER NOT NULL DEFAULT 7200,
  is_closed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. chat_participants tablosu
CREATE TABLE IF NOT EXISTS chat_participants (
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (room_id, fid)
);

-- 3. chat_messages tablosu
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_chat_rooms_match_id ON chat_rooms(match_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_is_closed ON chat_rooms(is_closed);
CREATE INDEX IF NOT EXISTS idx_chat_participants_fid ON chat_participants(fid);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(room_id, created_at DESC);

-- RLS Etkinleştir
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their chat rooms"
  ON chat_rooms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_participants
      WHERE chat_participants.room_id = chat_rooms.id
        AND chat_participants.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
  );

CREATE POLICY "Service role can manage chat rooms"
  ON chat_rooms FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
  WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

CREATE POLICY "Users can view participants in their rooms"
  ON chat_participants FOR SELECT
  USING (
    fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR EXISTS (
      SELECT 1 FROM chat_participants cp
      WHERE cp.room_id = chat_participants.room_id
        AND cp.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
  );

CREATE POLICY "Service role can manage participants"
  ON chat_participants FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
  WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

CREATE POLICY "Users can view messages in their rooms"
  ON chat_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_participants
      WHERE chat_participants.room_id = chat_messages.room_id
        AND chat_participants.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
  );

CREATE POLICY "Users can send messages in open rooms"
  ON chat_messages FOR INSERT
  WITH CHECK (
    sender_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    AND EXISTS (
      SELECT 1 FROM chat_participants
      WHERE chat_participants.room_id = chat_messages.room_id
        AND chat_participants.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
    AND EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE chat_rooms.id = chat_messages.room_id
        AND chat_rooms.is_closed = false
        AND (
          chat_rooms.first_join_at IS NULL
          OR now() <= (chat_rooms.first_join_at + (chat_rooms.ttl_seconds || ' seconds')::interval)
        )
    )
  );

-- Realtime için chat_messages tablosunu yayınla
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Helper fonksiyonlar
CREATE OR REPLACE FUNCTION close_expired_chat_rooms()
RETURNS INTEGER AS $$
DECLARE
  closed_count INTEGER;
BEGIN
  WITH updated_rooms AS (
    UPDATE chat_rooms
    SET is_closed = true, closed_at = now()
    WHERE is_closed = false
      AND first_join_at IS NOT NULL
      AND now() > (first_join_at + (ttl_seconds || ' seconds')::interval)
    RETURNING id, match_id
  ),
  updated_matches AS (
    UPDATE matches
    SET status = 'completed', completed_at = now()
    WHERE id IN (SELECT match_id FROM updated_rooms)
      AND status != 'completed'
    RETURNING id
  )
  SELECT COUNT(*) INTO closed_count FROM updated_rooms;
  RETURN closed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Başarılı mesajı
SELECT 'Chat tables created successfully! ✅' as status;
```

**Çalıştırdıktan sonra kontrol et:**
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('chat_rooms', 'chat_participants', 'chat_messages');
```

Şimdi 3 satır dönmeli. ✅

---

### Adım 3: Mevcut Accepted Match'ler İçin Chat Room Oluştur

Şu anda accepted durumda olan ama chat room'u olmayan match'ler için:

```sql
-- Accepted match'leri kontrol et
SELECT
    m.id,
    m.user_a_fid,
    m.user_b_fid,
    m.status,
    cr.id as chat_room_id
FROM matches m
LEFT JOIN chat_rooms cr ON cr.match_id = m.id
WHERE m.status = 'accepted'
  AND (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
ORDER BY m.created_at DESC;
```

**Eğer chat_room_id NULL ise**, o match için chat room oluştur:

```sql
-- Mevcut accepted match'ler için chat room oluştur
DO $$
DECLARE
  match_record RECORD;
  new_room_id UUID;
BEGIN
  FOR match_record IN
    SELECT m.id, m.user_a_fid, m.user_b_fid
    FROM matches m
    LEFT JOIN chat_rooms cr ON cr.match_id = m.id
    WHERE m.status = 'accepted'
      AND cr.id IS NULL
  LOOP
    -- Chat room oluştur
    INSERT INTO chat_rooms (match_id, opened_at)
    VALUES (match_record.id, now())
    RETURNING id INTO new_room_id;

    -- Katılımcıları ekle
    INSERT INTO chat_participants (room_id, fid)
    VALUES
      (new_room_id, match_record.user_a_fid),
      (new_room_id, match_record.user_b_fid);

    RAISE NOTICE 'Chat room % created for match %', new_room_id, match_record.id;
  END LOOP;
END $$;
```

---

### Adım 4: Frontend'i Kontrol Et

Inbox sayfasında chat room'u çekmek için `fetchChatRooms()` fonksiyonu var. Kontrol edelim:

**Problem olabilecek yer:** `/app/mini/inbox/page.tsx` içinde:

```typescript
const fetchChatRooms = async (matches: Match[]) => {
  try {
    const { supabase: sb } = await import('@/lib/supabase');
    const { data, error } = await sb
      .from('chat_rooms')
      .select('id, match_id')
      .in('match_id', matches.map(m => m.id));

    if (data) {
      const newMap = new Map<string, string>();
      data.forEach((room: any) => {
        newMap.set(room.match_id, room.id);
      });
      setChatRoomMap(newMap);
    }
  } catch (error) {
    console.error('Error fetching chat rooms:', error);
  }
};
```

Bu fonksiyon **client-side Supabase** kullanıyor. RLS policy'leri burada devreye giriyor.

**Sorun:** Eğer kullanıcı authenticated değilse veya JWT claims doğru set edilmemişse, RLS chat room'u göstermeyebilir.

---

### Adım 5: Test Et

1. **Supabase'de kontrol et:**
```sql
-- Senin match'lerin için chat room var mı?
SELECT
    m.id as match_id,
    m.status,
    cr.id as chat_room_id,
    cr.created_at
FROM matches m
LEFT JOIN chat_rooms cr ON cr.match_id = m.id
WHERE (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  AND m.status = 'accepted'
ORDER BY m.created_at DESC;
```

2. **Browser Console'da kontrol et:**
   - Inbox sayfasını aç
   - F12 → Console
   - "Error fetching chat rooms" var mı?
   - Network tabında `/api/matches` çağrısını kontrol et

3. **Chat room'u manuel test et:**
```sql
-- Chat room ID'sini al
SELECT id FROM chat_rooms
WHERE match_id = 'MATCH_ID_BURAYA';

-- Sonra browser'da aç:
-- https://your-app.vercel.app/mini/chat/{CHAT_ROOM_ID}
```

---

## 🚨 Hızlı Test Senaryosu

### Senaryo 1: Tabloları Oluştur ve Test Et

```bash
# Terminal'de
cd /Users/Cengizhan/Desktop/meetshippermini-app

# Migration'ı production'a uygula (yukarıdaki SQL'i Supabase'de çalıştır)

# Sonra browser'da test et:
# 1. https://your-app.vercel.app/mini/inbox
# 2. Accepted match'i seç
# 3. "Open Chat" butonu görünüyor mu?
```

### Senaryo 2: Mevcut Accepted Match'ler İçin Backfill

```sql
-- 1. Kontrol et
SELECT COUNT(*) FROM matches WHERE status = 'accepted';
SELECT COUNT(*) FROM chat_rooms;

-- 2. Fark varsa, backfill yap (yukarıdaki DO block'u çalıştır)

-- 3. Tekrar kontrol et
SELECT COUNT(*) FROM chat_rooms;
```

---

## 🐛 Debugging

### Problem: "Loading chat room..." sonsuza kadar kalıyor

**Sebep 1:** Chat room hiç oluşturulmamış
```sql
-- Kontrol:
SELECT * FROM chat_rooms WHERE match_id = 'YOUR_MATCH_ID';
-- Boş dönüyorsa, Adım 3'ü yap (backfill)
```

**Sebep 2:** RLS policy kullanıcıya göstermiyor
```sql
-- Service role ile kontrol et (SQL Editor'da):
SELECT * FROM chat_rooms;  -- Tümünü görmeli

-- Eğer frontend göremiyorsa, RLS sorunu var
```

**Sebep 3:** Frontend fetch hatası
```javascript
// Browser console'da:
console.log(chatRoomMap);  // Empty map mı?
```

---

### Problem: "Open Chat" butonu hiç görünmüyor

**Sebep:** `chatRoomId` state'de yok.

**Çözüm:**
```typescript
// inbox/page.tsx içinde useEffect'e log ekle:
useEffect(() => {
  console.log('Chat room map:', chatRoomMap);
  console.log('Selected match:', selectedMatch?.id);
}, [chatRoomMap, selectedMatch]);
```

---

## ✅ Çözüm Checklist

- [ ] Adım 1: Tabloları kontrol et (`SELECT table_name...`)
- [ ] Adım 2: Migration'ı uygula (SQL Editor'da)
- [ ] Adım 3: Mevcut match'ler için backfill yap
- [ ] Adım 4: Browser'da inbox sayfasını aç, F12 Console kontrol et
- [ ] Adım 5: "Open Chat" butonu görünüyor mu?
- [ ] Adım 6: Chat sayfası açılıyor mu? (`/mini/chat/[roomId]`)

---

## 🎯 Özet: Hızlı Çözüm (5 Dakika)

```sql
-- 1. Supabase SQL Editor'da migration'ı çalıştır (Adım 2'deki tüm SQL)

-- 2. Backfill yap:
DO $$
DECLARE
  match_record RECORD;
  new_room_id UUID;
BEGIN
  FOR match_record IN
    SELECT m.id, m.user_a_fid, m.user_b_fid
    FROM matches m
    LEFT JOIN chat_rooms cr ON cr.match_id = m.id
    WHERE m.status = 'accepted' AND cr.id IS NULL
  LOOP
    INSERT INTO chat_rooms (match_id, opened_at)
    VALUES (match_record.id, now())
    RETURNING id INTO new_room_id;

    INSERT INTO chat_participants (room_id, fid)
    VALUES (new_room_id, match_record.user_a_fid),
           (new_room_id, match_record.user_b_fid);
  END LOOP;
END $$;

-- 3. Kontrol et:
SELECT
    m.id,
    m.status,
    cr.id as chat_room_id
FROM matches m
LEFT JOIN chat_rooms cr ON cr.match_id = m.id
WHERE (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  AND m.status = 'accepted';

-- 4. Browser'ı refresh et ve test et!
```

---

**Sorununuz çözülmezse, browser console'da ve server logs'unda gördüğünüz hata mesajlarını paylaşın!** 🔍
