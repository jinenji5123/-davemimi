-- ========================================================
-- 🌿 생활지원사 휴가관리 시스템 (CareLeave Manager)
-- Supabase 즉시 연동 및 웹 권한 설정 SQL 스크립트
-- ========================================================
-- 💡 Supabase 대시보드(SQL Editor)에서 이 스크립트 전체를 실행하시면
--    웹 화면(index.html)에서 즉시 데이터 읽기/쓰기가 가능해집니다.

-- 1. UUID 확장 모듈 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. 사용자 프로필 테이블 (독립 실행 및 Auth 연동 겸용)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'worker' CHECK (role IN ('worker', 'manager', 'admin')),
    zone_code TEXT NOT NULL DEFAULT '1권역',
    hire_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기존 auth.users 외래키 제약조건이 있다면 제거하여 웹 데모에서도 즉시 사용 가능하도록 설정
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- 3. 휴가 유형 테이블
CREATE TABLE IF NOT EXISTS public.leave_types (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    deduction_days NUMERIC(3, 1) NOT NULL DEFAULT 1.0,
    requires_document BOOLEAN NOT NULL DEFAULT false,
    is_paid BOOLEAN NOT NULL DEFAULT true,
    description TEXT
);

-- 4. 연차 잔여일수 테이블
CREATE TABLE IF NOT EXISTS public.leave_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    year INT NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    total_days NUMERIC(4, 1) NOT NULL DEFAULT 15.0,
    used_days NUMERIC(4, 1) NOT NULL DEFAULT 0.0,
    remaining_days NUMERIC(4, 1) GENERATED ALWAYS AS (total_days - used_days) STORED,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_year UNIQUE (user_id, year)
);

-- 5. 휴가 신청 테이블
CREATE TABLE IF NOT EXISTS public.leave_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    leave_type_id INT NOT NULL REFERENCES public.leave_types(id),
    substitute_id UUID REFERENCES public.profiles(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    substitute_status TEXT NOT NULL DEFAULT 'pending' CHECK (substitute_status IN ('pending', 'accepted', 'rejected')),
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'manager_approved', 'final_approved', 'rejected')),
    reject_reason TEXT,
    document_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ
);

-- ========================================================
-- 🎁 초기 시드 데이터 삽입
-- ========================================================

-- 휴가 종류 등록
INSERT INTO public.leave_types (id, name, deduction_days, requires_document, is_paid, description)
VALUES
    (1, '전일 연차', 1.0, false, true, '하루 종일 휴가 사용 (-1.0일)'),
    (2, '오전 반차', 0.5, false, true, '오전 근로 면제 (-0.5일)'),
    (3, '오후 반차', 0.5, false, true, '오후 근로 면제 (-0.5일)'),
    (4, '병가', 1.0, true, false, '질병 또는 부상 치료 (진단서 필수)'),
    (5, '공가', 0.0, true, true, '국가 건강검진, 투표, 교육 등 (0일 차감)'),
    (6, '경조사 휴가', 1.0, true, true, '본인 및 가족 경조사')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    deduction_days = EXCLUDED.deduction_days;

-- 생활지원사 및 관리자 기본 프로필 등록
INSERT INTO public.profiles (id, name, phone, role, zone_code)
VALUES
    ('a0000000-0000-0000-0000-000000000001', '김돌봄', '010-1234-5678', 'worker', '1권역'),
    ('a0000000-0000-0000-0000-000000000002', '이서포트', '010-2345-6789', 'worker', '1권역'),
    ('a0000000-0000-0000-0000-000000000003', '박돌봄', '010-3456-7890', 'worker', '2권역'),
    ('a0000000-0000-0000-0000-000000000004', '정복지 (전담)', '010-9999-8888', 'manager', '관리팀')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    role = EXCLUDED.role,
    zone_code = EXCLUDED.zone_code;

-- 김돌봄 생활지원사의 2026년 연차 잔여일수 등록
INSERT INTO public.leave_balances (user_id, year, total_days, used_days)
VALUES
    ('a0000000-0000-0000-0000-000000000001', EXTRACT(YEAR FROM CURRENT_DATE)::INT, 15.0, 3.5)
ON CONFLICT (user_id, year) DO UPDATE SET
    total_days = EXCLUDED.total_days;

-- ========================================================
-- 🛡️ Row Level Security (RLS) 정책 (웹 클라이언트 공개 권한)
-- ========================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

-- 기존 정책 정리
DROP POLICY IF EXISTS "leave_types_select_all" ON public.leave_types;
DROP POLICY IF EXISTS "profiles_select_all" ON public.profiles;
DROP POLICY IF EXISTS "profiles_all" ON public.profiles;
DROP POLICY IF EXISTS "leave_balances_select" ON public.leave_balances;
DROP POLICY IF EXISTS "leave_balances_all" ON public.leave_balances;
DROP POLICY IF EXISTS "leave_requests_select" ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_insert" ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_update" ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_all" ON public.leave_requests;

-- 웹 브라우저(anon)에서도 읽기/쓰기가 가능하도록 정책 적용
CREATE POLICY "leave_types_select_all" ON public.leave_types
    FOR SELECT TO public USING (true);

CREATE POLICY "profiles_all" ON public.profiles
    FOR ALL TO public USING (true) WITH CHECK (true);

CREATE POLICY "leave_balances_all" ON public.leave_balances
    FOR ALL TO public USING (true) WITH CHECK (true);

CREATE POLICY "leave_requests_all" ON public.leave_requests
    FOR ALL TO public USING (true) WITH CHECK (true);

-- ========================================================
-- ⚡ 연차 자동 차감 트리거
-- ========================================================
CREATE OR REPLACE FUNCTION public.handle_leave_approval()
RETURNS TRIGGER AS $$
DECLARE
    deduct_amount NUMERIC(3, 1);
    days_count INT;
    total_deduct NUMERIC(4, 1);
BEGIN
    IF NEW.status = 'final_approved' AND (OLD.status IS NULL OR OLD.status != 'final_approved') THEN
        SELECT deduction_days INTO deduct_amount
        FROM public.leave_types
        WHERE id = NEW.leave_type_id;

        days_count := (NEW.end_date - NEW.start_date) + 1;
        total_deduct := COALESCE(deduct_amount, 1.0) * GREATEST(days_count, 1);

        UPDATE public.leave_balances
        SET used_days = used_days + total_deduct,
            updated_at = NOW()
        WHERE user_id = NEW.user_id
          AND year = EXTRACT(YEAR FROM NEW.start_date)::INT;

        NEW.approved_at := NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_leave_request_approved ON public.leave_requests;
CREATE TRIGGER on_leave_request_approved
    BEFORE UPDATE ON public.leave_requests
    FOR EACH ROW EXECUTE FUNCTION public.handle_leave_approval();
