# Hızlı Çözüm: Chat Room Görünmüyor

## 🎯 Sorun
İki taraf accepted olunca "Loading chat room..." yazıyor, chat linki çıkmıyor.

## ⚡ Hızlı Çözüm (3 Adım)

### 1️⃣ Supabase'de Tabloları Kontrol Et

**Supabase Dashboard** → **SQL Editor** → Şunu çalıştır:

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('chat_rooms', 'chat_participants', 'chat_messages');
```

**3 satır dönmüyorsa** → Adım 2'ye geç
**3 satır dönüyorsa** → Adım 3'e geç

---

### 2️⃣ Tabloları Oluştur (Tek Seferde)

**Supabase SQL Editor**'da **bütün** aşağıdaki kodu **kopyala-yapıştır** ve **Run**:

```sql
-- Chat rooms tablosu
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

CREATE TABLE IF NOT EXISTS chat_participants (
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  PRIMARY KEY (room_id, fid)
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_rooms_match_id ON chat_rooms(match_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);

ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their chat rooms" ON chat_rooms FOR SELECT
USING (EXISTS (
  SELECT 1 FROM chat_participants
  WHERE chat_participants.room_id = chat_rooms.id
    AND chat_participants.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
));

CREATE POLICY "Service role can manage chat rooms" ON chat_rooms FOR ALL
USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

CREATE POLICY "Users can view participants" ON chat_participants FOR SELECT
USING (fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  OR EXISTS (SELECT 1 FROM chat_participants cp WHERE cp.room_id = chat_participants.room_id
    AND cp.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint));

CREATE POLICY "Service role can manage participants" ON chat_participants FOR ALL
USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

CREATE POLICY "Users can view messages" ON chat_messages FOR SELECT
USING (EXISTS (
  SELECT 1 FROM chat_participants
  WHERE chat_participants.room_id = chat_messages.room_id
    AND chat_participants.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
));

CREATE POLICY "Users can send messages" ON chat_messages FOR INSERT
WITH CHECK (
  sender_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  AND EXISTS (SELECT 1 FROM chat_participants WHERE room_id = chat_messages.room_id AND fid = sender_fid)
  AND EXISTS (SELECT 1 FROM chat_rooms WHERE id = chat_messages.room_id AND is_closed = false)
);

ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

SELECT '✅ Tablolar başarıyla oluşturuldu!' as sonuc;
```

---

### 3️⃣ Mevcut Accepted Match'ler İçin Chat Room Oluştur

**Senin FID'in için:**

```sql
-- Kontrol et: Chat room var mı?
SELECT
    m.id as match_id,
    m.status,
    cr.id as chat_room_id
FROM matches m
LEFT JOIN chat_rooms cr ON cr.match_id = m.id
WHERE (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  AND m.status = 'accepted';
```

**Eğer chat_room_id NULL ise**, şunu çalıştır:

```sql
-- Accepted match'ler için chat room oluştur
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

    RAISE NOTICE 'Chat room % oluşturuldu (match: %)', new_room_id, match_record.id;
  END LOOP;
END $$;
```

---

### 4️⃣ Test Et

1. **Browser'ı refresh et**
2. **Inbox** sayfasına git
3. **Accepted match'i** seç
4. **"Open Chat" butonu** görünmeli ✅

---

## 🐛 Hala Çalışmıyor mu?

### Debug 1: Chat room oluştu mu kontrol et
```sql
SELECT * FROM chat_rooms
WHERE match_id IN (
  SELECT id FROM matches WHERE user_a_fid = 543581 OR user_b_fid = 543581
);
```

### Debug 2: Browser Console kontrol et
- F12 → Console
- Hata var mı?
- Network tabında `/api/matches` isteğine bak

### Debug 3: Manuel test
```sql
-- Chat room ID'sini al
SELECT id, match_id FROM chat_rooms LIMIT 1;

-- Sonra browser'da aç:
-- https://your-app.vercel.app/mini/chat/{CHAT_ROOM_ID}
```

---

## 📊 Özet

| Adım | Ne Yapıyor | Süre |
|------|------------|------|
| 1️⃣ | Tabloları kontrol et | 10 sn |
| 2️⃣ | Tabloları oluştur | 30 sn |
| 3️⃣ | Mevcut match'ler için backfill | 20 sn |
| 4️⃣ | Test et | 30 sn |
| **Toplam** | | **~2 dakika** |

---

## ✅ Başarı Kriterleri

Çözüm başarılı olduysa:
- ✅ Inbox'ta "Open Chat" butonu görünüyor
- ✅ Chat sayfası açılıyor
- ✅ Mesaj gönderebiliyorsun
- ✅ 2 saatlik countdown başlıyor

---

**Daha fazla detay için:** `CHAT_ROOM_FIX_TR.md` dosyasına bak.
