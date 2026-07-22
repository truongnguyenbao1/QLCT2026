-- From migration_add_payment_image.sql
-- Thêm cột lưu URL ảnh giao dịch khi khách thuê xác nhận thanh toán
ALTER TABLE public.hoadon ADD COLUMN IF NOT EXISTS payment_image_url TEXT;

-- From migration_momo_qr.sql
-- =========================================================================
-- MIGRATION: Thêm chức năng tải ảnh mã QR MoMo
-- Chạy script này trong Supabase SQL Editor
-- =========================================================================

-- 1. Thêm cột momo_qr_url vào bảng caidat_thanhtoan
ALTER TABLE public.caidat_thanhtoan 
ADD COLUMN IF NOT EXISTS momo_qr_url TEXT;

-- From migration_notifications.sql
-- Cập nhật CHECK constraint cho cột status của bảng hoadon nếu cần
    ALTER TABLE public.hoadon DROP CONSTRAINT IF EXISTS hoadon_status_check;

-- From migration_notifications.sql
ALTER TABLE public.hoadon ADD CONSTRAINT hoadon_status_check CHECK (status IN ('PENDING', 'CONFIRMED_BY_TENANT', 'CONFIRMED_BY_OWNER', 'PAID', 'OVERDUE'));

-- From migration_notifications_update.sql
-- Cập nhật bảng thongbao hiện có
ALTER TABLE public.thongbao
  ADD COLUMN IF NOT EXISTS type VARCHAR(50) NOT NULL DEFAULT 'ANNOUNCEMENT' CHECK (type IN ('ANNOUNCEMENT', 'ISSUE', 'SYSTEM')),
  ADD COLUMN IF NOT EXISTS image_url TEXT;

-- From migration_payment_settings.sql
-- =========================================================================
-- MIGRATION: Thêm bảng cài đặt thanh toán (caidat_thanhtoan)
-- Chạy script này trong Supabase SQL Editor
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: caidat_thanhtoan (Payment Settings)
-- Lưu thông tin tài khoản ngân hàng & ví điện tử của chủ trọ
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.caidat_thanhtoan (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES public.users(iduser) ON DELETE CASCADE,

    -- Thông tin tài khoản ngân hàng
    bank_code    VARCHAR(20),          -- Mã ngân hàng (VD: VCB, TCB, MB)
    bank_name    VARCHAR(255),         -- Tên ngân hàng đầy đủ
    account_number VARCHAR(50),        -- Số tài khoản
    account_name  VARCHAR(255),        -- Tên chủ tài khoản (IN HOA)

    -- Nội dung chuyển khoản mẫu
    transfer_note_template TEXT DEFAULT 'Phong {room} thang {month}/{year}',

    -- Ví điện tử
    momo_phone   VARCHAR(20),          -- SĐT Momo
    vnpay_qr     TEXT,                 -- Mã VNPay QR (nếu có)

    -- Metadata
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Mỗi user chỉ có 1 bộ cài đặt
    CONSTRAINT unique_payment_settings_per_user UNIQUE (user_id)
);

-- From migration_payment_settings.sql
COMMENT ON TABLE public.caidat_thanhtoan IS 'Cài đặt thông tin thanh toán của chủ trọ (tài khoản ngân hàng, VietQR, MoMo)';

-- From migration_payment_settings.sql
-- ── Index ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_caidat_thanhtoan_user ON public.caidat_thanhtoan(user_id);

-- From migration_split_invoice.sql
-- =========================================================================
-- MIGRATION: Split hoadon into hoadon and chitiethoadon
-- WARNING: This will drop existing data in hoadon and chitiethoadon.
-- =========================================================================

-- 1. Xóa bảng hiện tại
DROP TABLE IF EXISTS public.chitiethoadon CASCADE;

-- From migration_split_invoice.sql
DROP TABLE IF EXISTS public.hoadon CASCADE;

-- From migration_split_invoice.sql
-- 2. Tạo lại bảng hoadon (Thông tin chung)
CREATE TABLE public.hoadon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.phong(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES public.khachthue(id) ON DELETE SET NULL,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INTEGER NOT NULL CHECK (year >= 2020),
    
    total_amount NUMERIC NOT NULL DEFAULT 0,
    
    -- Thanh toán
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (
        status IN ('PENDING', 'CONFIRMED_BY_TENANT', 'CONFIRMED_BY_OWNER', 'PAID', 'OVERDUE')
    ),
    due_date TIMESTAMPTZ NOT NULL,
    paid_at TIMESTAMPTZ,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    
    -- Audit & khóa hóa đơn
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES public.users(iduser) ON DELETE SET NULL,
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT unique_invoice_per_month_year UNIQUE (room_id, month, year)
);

-- From migration_split_invoice.sql
COMMENT ON TABLE public.hoadon IS 'Thông tin tổng quan hóa đơn tiền phòng hàng tháng';

-- From migration_split_invoice.sql
CREATE INDEX IF NOT EXISTS idx_hoadon_phong_ky ON public.hoadon(room_id, year, month);

-- From migration_split_invoice.sql
-- 3. Tạo lại bảng chitiethoadon (Chi tiết hóa đơn)
CREATE TABLE public.chitiethoadon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL UNIQUE REFERENCES public.hoadon(id) ON DELETE CASCADE,
    
    -- Chỉ số điện
    electric_prev_reading NUMERIC NOT NULL DEFAULT 0,
    electric_curr_reading NUMERIC NOT NULL DEFAULT 0,
    electric_unit_price NUMERIC NOT NULL DEFAULT 3500,
    
    -- Chỉ số nước
    water_prev_reading NUMERIC NOT NULL DEFAULT 0,
    water_curr_reading NUMERIC NOT NULL DEFAULT 0,
    water_unit_price NUMERIC NOT NULL DEFAULT 15000,
    
    -- Tiền phòng & dịch vụ cố định
    rent_amount NUMERIC NOT NULL DEFAULT 0,
    service_amount NUMERIC NOT NULL DEFAULT 0,
    
    -- Các khoản khác
    other_amount NUMERIC DEFAULT 0,
    other_description TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- From migration_split_invoice.sql
COMMENT ON TABLE public.chitiethoadon IS 'Chi tiết các khoản phí của hóa đơn';

-- From migration_split_payment.sql
-- 2. Xóa các cột thanh toán khỏi bảng hoadon
ALTER TABLE public.hoadon
DROP COLUMN IF EXISTS paid_at,
DROP COLUMN IF EXISTS payment_method,
DROP COLUMN IF EXISTS transaction_id;

-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.users (
  iduser uuid NOT NULL,
  tenuser character varying,
  email character varying,
  sdt character varying,
  ngaytao date DEFAULT CURRENT_DATE,
  ngaycapnhat date,
  quyenhan character varying CHECK (quyenhan::text = ANY (ARRAY['admin'::character varying, 'khách thuê'::character varying]::text[])),
  property_id uuid,
  room_id uuid,
  has_accepted_privacy_policy boolean DEFAULT false,
  CONSTRAINT users_pkey PRIMARY KEY (iduser),
  CONSTRAINT users_iduser_fkey FOREIGN KEY (iduser) REFERENCES auth.users(id),
  CONSTRAINT fk_users_nhatro FOREIGN KEY (property_id) REFERENCES public.nhatro(id)
);
CREATE TABLE public.nhatro (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL,
  address character varying,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  iduser uuid,
  CONSTRAINT nhatro_pkey PRIMARY KEY (id),
  CONSTRAINT nhatro_iduser_fkey FOREIGN KEY (iduser) REFERENCES auth.users(id)
);
CREATE TABLE public.phong (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL,
  room_number character varying NOT NULL,
  floor integer DEFAULT 1,
  area numeric NOT NULL DEFAULT 0,
  rent_price numeric NOT NULL DEFAULT 0,
  electric_price numeric NOT NULL DEFAULT 3500,
  water_price numeric NOT NULL DEFAULT 15000,
  service_price numeric NOT NULL DEFAULT 0,
  status character varying NOT NULL DEFAULT 'EMPTY'::character varying CHECK (status::text = ANY (ARRAY['EMPTY'::character varying, 'OCCUPIED'::character varying, 'MAINTENANCE'::character varying]::text[])),
  amenities ARRAY DEFAULT '{}'::text[],
  description text,
  image_urls ARRAY DEFAULT '{}'::text[],
  max_occupants integer,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT phong_pkey PRIMARY KEY (id),
  CONSTRAINT phong_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.nhatro(id)
);
CREATE TABLE public.khachthue (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  property_id uuid,
  room_id uuid,
  user_id uuid,
  full_name character varying NOT NULL,
  phone_number character varying NOT NULL,
  cccd_number text,
  date_of_birth timestamp with time zone,
  email character varying,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT khachthue_pkey PRIMARY KEY (id),
  CONSTRAINT khachthue_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.nhatro(id),
  CONSTRAINT khachthue_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.phong(id),
  CONSTRAINT khachthue_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(iduser)
);
CREATE TABLE public.thuephong (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  room_id uuid NOT NULL,
  start_date timestamp with time zone NOT NULL,
  end_date timestamp with time zone,
  deposit_amount numeric NOT NULL DEFAULT 0,
  status character varying NOT NULL DEFAULT 'ACTIVE'::character varying CHECK (status::text = ANY (ARRAY['ACTIVE'::character varying, 'TERMINATED'::character varying, 'EXPIRED'::character varying]::text[])),
  contract_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT thuephong_pkey PRIMARY KEY (id),
  CONSTRAINT thuephong_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.khachthue(id),
  CONSTRAINT thuephong_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.phong(id)
);
CREATE TABLE public.chiso (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL,
  type character varying NOT NULL CHECK (type::text = ANY (ARRAY['ELECTRIC'::character varying, 'WATER'::character varying]::text[])),
  prev_reading numeric NOT NULL DEFAULT 0,
  curr_reading numeric NOT NULL DEFAULT 0,
  reading_date timestamp with time zone NOT NULL DEFAULT now(),
  unit_price numeric NOT NULL DEFAULT 0,
  month integer NOT NULL CHECK (month >= 1 AND month <= 12),
  year integer NOT NULL CHECK (year >= 2020),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT chiso_pkey PRIMARY KEY (id),
  CONSTRAINT chiso_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.phong(id)
);
CREATE TABLE public.nhatky_hethong (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  action character varying NOT NULL,
  table_name character varying NOT NULL,
  record_id character varying NOT NULL,
  new_value jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT nhatky_hethong_pkey PRIMARY KEY (id),
  CONSTRAINT nhatky_hethong_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(iduser)
);
CREATE TABLE public.thongbao (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  room_id uuid,
  sender_id uuid,
  receiver_id uuid,
  title character varying NOT NULL,
  content text NOT NULL,
  status character varying NOT NULL DEFAULT 'UNREAD'::character varying CHECK (status::text = ANY (ARRAY['UNREAD'::character varying, 'READ'::character varying]::text[])),
  sent_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  type character varying NOT NULL DEFAULT 'ANNOUNCEMENT'::character varying CHECK (type::text = ANY (ARRAY['ANNOUNCEMENT'::character varying, 'ISSUE'::character varying, 'SYSTEM'::character varying]::text[])),
  image_url text,
  CONSTRAINT thongbao_pkey PRIMARY KEY (id),
  CONSTRAINT thongbao_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.phong(id),
  CONSTRAINT thongbao_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(iduser),
  CONSTRAINT thongbao_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(iduser)
);
CREATE TABLE public.tailieudinhkem (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  notification_id uuid NOT NULL,
  file_name character varying NOT NULL,
  file_url text NOT NULL,
  file_size integer,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT tailieudinhkem_pkey PRIMARY KEY (id),
  CONSTRAINT tailieudinhkem_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.thongbao(id)
);
CREATE TABLE public.thuchi (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  type character varying NOT NULL CHECK (type::text = ANY (ARRAY['INCOME'::character varying, 'EXPENSE'::character varying]::text[])),
  category character varying,
  amount numeric NOT NULL DEFAULT 0,
  description text,
  transaction_date timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT thuchi_pkey PRIMARY KEY (id),
  CONSTRAINT thuchi_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(iduser)
);
CREATE TABLE public.caidat_thanhtoan (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  bank_code character varying,
  bank_name character varying,
  account_number character varying,
  account_name character varying,
  transfer_note_template text DEFAULT 'Phong {room} thang {month}/{year}'::text,
  momo_phone character varying,
  vnpay_qr text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  momo_qr_url text,
  CONSTRAINT caidat_thanhtoan_pkey PRIMARY KEY (id),
  CONSTRAINT caidat_thanhtoan_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(iduser)
);
CREATE TABLE public.hoadon (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL,
  tenant_id uuid,
  month integer NOT NULL CHECK (month >= 1 AND month <= 12),
  year integer NOT NULL CHECK (year >= 2020),
  total_amount numeric NOT NULL DEFAULT 0,
  status character varying NOT NULL DEFAULT 'PENDING'::character varying CHECK (status::text = ANY (ARRAY['PENDING'::character varying, 'CONFIRMED_BY_TENANT'::character varying, 'CONFIRMED_BY_OWNER'::character varying, 'PAID'::character varying, 'OVERDUE'::character varying]::text[])),
  due_date timestamp with time zone NOT NULL,
  paid_at timestamp with time zone,
  payment_method character varying,
  transaction_id character varying,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  created_by uuid,
  is_locked boolean NOT NULL DEFAULT false,
  payment_image_url text,
  CONSTRAINT hoadon_pkey PRIMARY KEY (id),
  CONSTRAINT hoadon_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.phong(id),
  CONSTRAINT hoadon_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.khachthue(id),
  CONSTRAINT hoadon_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(iduser)
);
CREATE TABLE public.chitiethoadon (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL UNIQUE,
  electric_prev_reading numeric NOT NULL DEFAULT 0,
  electric_curr_reading numeric NOT NULL DEFAULT 0,
  electric_unit_price numeric NOT NULL DEFAULT 3500,
  water_prev_reading numeric NOT NULL DEFAULT 0,
  water_curr_reading numeric NOT NULL DEFAULT 0,
  water_unit_price numeric NOT NULL DEFAULT 15000,
  rent_amount numeric NOT NULL DEFAULT 0,
  service_amount numeric NOT NULL DEFAULT 0,
  other_amount numeric DEFAULT 0,
  other_description text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT chitiethoadon_pkey PRIMARY KEY (id),
  CONSTRAINT chitiethoadon_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.hoadon(id)
);