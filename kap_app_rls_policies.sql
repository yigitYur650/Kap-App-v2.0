-- ============================================================
-- KAP-APP — Supabase Row Level Security Politikaları
-- ============================================================
-- Kurulum adımları:
--   1. Her tabloda RLS'yi etkinleştir
--   2. Politikaları sırayla uygula
--   3. auth.uid() → oturum açmış kullanıcının UUID'si (Supabase built-in)
-- ============================================================


-- ============================================================
-- YARDIMCI FONKSİYONLAR
-- ============================================================

-- Kullanıcının belirli bir gruba üye olup olmadığını döner
CREATE OR REPLACE FUNCTION is_group_member(p_group_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = p_group_id
      AND user_id  = auth.uid()
  );
$$;

-- Kullanıcının belirli bir grupta admin olup olmadığını döner
CREATE OR REPLACE FUNCTION is_group_admin(p_group_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = p_group_id
      AND user_id  = auth.uid()
      AND role     = 'admin'
  );
$$;


-- ============================================================
-- TABLO: users
-- ============================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Herkes kendi profilini görebilir
CREATE POLICY "users: kendi profilini gör"
ON users FOR SELECT
USING (id = auth.uid());

-- Grup üyeleri birbirinin display_name alanını görebilir
CREATE POLICY "users: aynı gruptaki üyeleri gör"
ON users FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM group_members gm1
    JOIN   group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE  gm1.user_id = auth.uid()
      AND  gm2.user_id = users.id
  )
);

-- Kullanıcı yalnızca kendi profilini güncelleyebilir
CREATE POLICY "users: kendi profilini güncelle"
ON users FOR UPDATE
USING  (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Kayıt sırasında INSERT (auth hook ile yönetilir)
CREATE POLICY "users: kayıt sırasında oluştur"
ON users FOR INSERT
WITH CHECK (id = auth.uid());

-- Silme yasak — hesap kapatma backend servisinden yapılır


-- ============================================================
-- TABLO: groups
-- ============================================================
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- Yalnızca üye olduğun grupları görebilirsin
CREATE POLICY "groups: üyesi olduğun grupları gör"
ON groups FOR SELECT
USING (is_group_member(id));

-- Herhangi bir oturum açmış kullanıcı grup oluşturabilir
CREATE POLICY "groups: grup oluştur"
ON groups FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- Yalnızca grup admini grubu güncelleyebilir
CREATE POLICY "groups: admin güncelleyebilir"
ON groups FOR UPDATE
USING  (is_group_admin(id))
WITH CHECK (is_group_admin(id));

-- Yalnızca grup admini grubu silebilir
CREATE POLICY "groups: admin silebilir"
ON groups FOR DELETE
USING (is_group_admin(id));


-- ============================================================
-- TABLO: group_members
-- ============================================================
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Aynı gruptaki tüm üyeleri görebilirsin
CREATE POLICY "group_members: aynı gruptakileri gör"
ON group_members FOR SELECT
USING (is_group_member(group_id));

-- Gruba katılma: unique_code ile davet akışı
CREATE POLICY "group_members: gruba katıl"
ON group_members FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Admin rol değiştirebilir
CREATE POLICY "group_members: admin rol değiştirir"
ON group_members FOR UPDATE
USING  (is_group_admin(group_id))
WITH CHECK (is_group_admin(group_id));

-- Kullanıcı kendini çıkarabilir veya admin çıkarabilir
CREATE POLICY "group_members: gruptan ayrıl veya çıkar"
ON group_members FOR DELETE
USING (
  user_id = auth.uid()
  OR is_group_admin(group_id)
);


-- ============================================================
-- TABLO: requests
-- ============================================================
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;

-- Özel istek kuralı:
--   is_private = false → gruptaki herkes görebilir
--   is_private = true  → yalnızca private_to veya requested_by görebilir
CREATE POLICY "requests: listele (özel istekler gizli)"
ON requests FOR SELECT
USING (
  is_group_member(group_id)
  AND (
    is_private = false
    OR private_to   = auth.uid()
    OR requested_by = auth.uid()
  )
);

-- Gruba üye olan kişi istek oluşturabilir
CREATE POLICY "requests: istek oluştur"
ON requests FOR INSERT
WITH CHECK (
  is_group_member(group_id)
  AND requested_by = auth.uid()
  AND (
    is_private = false
    OR EXISTS (
      SELECT 1 FROM group_members
      WHERE group_id = requests.group_id
        AND user_id  = requests.private_to
    )
  )
);

-- Sadece isteği oluşturan güncelleyebilir
CREATE POLICY "requests: kendi isteğini güncelle"
ON requests FOR UPDATE
USING  (requested_by = auth.uid())
WITH CHECK (requested_by = auth.uid());

-- İsteği oluşturan veya grup admini silebilir
CREATE POLICY "requests: sil"
ON requests FOR DELETE
USING (
  requested_by = auth.uid()
  OR is_group_admin(group_id)
);


-- ============================================================
-- TABLO: inventory
-- ============================================================
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

-- Gruba üye olan herkes envanter görebilir
CREATE POLICY "inventory: üyeler görebilir"
ON inventory FOR SELECT
USING (is_group_member(group_id));

-- Gruba üye olan herkes ürün ekleyebilir
CREATE POLICY "inventory: üye ürün ekler"
ON inventory FOR INSERT
WITH CHECK (
  is_group_member(group_id)
  AND added_by = auth.uid()
);

-- Gruba üye olan herkes stok durumunu güncelleyebilir
CREATE POLICY "inventory: üye stok günceller"
ON inventory FOR UPDATE
USING  (is_group_member(group_id))
WITH CHECK (is_group_member(group_id));

-- Ekleyen kişi veya grup admini silebilir
CREATE POLICY "inventory: sil"
ON inventory FOR DELETE
USING (
  added_by = auth.uid()
  OR is_group_admin(group_id)
);


-- ============================================================
-- TABLO: recipes  (Gelecek Sürüm)
-- ============================================================
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;

-- is_public = true → tüm oturum açmış kullanıcılar görebilir
-- is_public = false → yalnızca aynı gruptakiler görebilir
CREATE POLICY "recipes: herkese açık tarifleri gör"
ON recipes FOR SELECT
USING (
  is_public = true
  OR is_group_member(group_id)
);

-- Gruba üye tarif ekleyebilir
CREATE POLICY "recipes: üye tarif ekler"
ON recipes FOR INSERT
WITH CHECK (
  is_group_member(group_id)
  AND created_by = auth.uid()
);

-- Yalnızca tarifi ekleyen güncelleyebilir
CREATE POLICY "recipes: tarifi oluşturan günceller"
ON recipes FOR UPDATE
USING  (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- Tarifi oluşturan veya grup admini silebilir
CREATE POLICY "recipes: sil"
ON recipes FOR DELETE
USING (
  created_by = auth.uid()
  OR is_group_admin(group_id)
);


-- ============================================================
-- TABLO: recipe_items  (Gelecek Sürüm)
-- ============================================================
ALTER TABLE recipe_items ENABLE ROW LEVEL SECURITY;

-- Tarifi görebilen kişi malzemeleri de görebilir
CREATE POLICY "recipe_items: tarifi görenler malzemeleri de görebilir"
ON recipe_items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM recipes r
    WHERE  r.id = recipe_items.recipe_id
      AND (
        r.is_public = true
        OR is_group_member(r.group_id)
      )
  )
);

-- Tarifi oluşturan malzeme ekleyebilir
CREATE POLICY "recipe_items: tarif sahibi malzeme ekler"
ON recipe_items FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM recipes r
    WHERE r.id         = recipe_items.recipe_id
      AND r.created_by = auth.uid()
  )
);

-- Tarifi oluşturan malzeme güncelleyebilir
CREATE POLICY "recipe_items: tarif sahibi günceller"
ON recipe_items FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM recipes r
    WHERE r.id         = recipe_items.recipe_id
      AND r.created_by = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM recipes r
    WHERE r.id         = recipe_items.recipe_id
      AND r.created_by = auth.uid()
  )
);

-- Tarifi oluşturan veya grup admini malzeme silebilir
CREATE POLICY "recipe_items: sil"
ON recipe_items FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM recipes r
    WHERE r.id = recipe_items.recipe_id
      AND (
        r.created_by = auth.uid()
        OR is_group_admin(r.group_id)
      )
  )
);


-- ============================================================
-- GÜVENLİ VIEW: unique_code ile kullanıcı arama
-- Hassas alanları (email, email_verified vb.) gizler;
-- yalnızca display_name + unique_code döner.
-- ============================================================
CREATE OR REPLACE VIEW public_user_lookup
WITH (security_invoker = true) AS
  SELECT id, display_name, unique_code
  FROM   users;
