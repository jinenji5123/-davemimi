-- ========================================================
-- 🌿 생활지원사 휴가관리 시스템 (CareLeave Manager)
-- Supabase PostgreSQL 초기 스키마 및 RLS 보안 정책
-- ========================================================

-- 1. UUID 확장 모듈 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. 사용자 프로필 테이블 (Supabase Auth와 1:1 연동)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'worker' CHECK (role IN ('worker', 'manager', 'admin')),
    zone_code TEXT NOT NULL DEFAULT '1권역', -- 담당 권역 (예: 1권역, 2권역)
    hire_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 휴가 유형 테이블
CREATE TABLE IF NOT EXISTS public.leave_types (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    deduction_days NUMERIC(3, 1) NOT NULL DEFAULT 1.0, -- 차감 일수 (1.0, 0.5 등)
    requires_document BOOLEAN NOT NULL DEFAULT false, -- 증빙 필수 여부
    is_paid BOOLEAN NOT NULL DEFAULT true,             -- 유급 여부
    description TEXT
);

-- 기본 휴가 유형 시드 데이터
INSERT INTO public.leave_types (name, deduction_days, requires_document, is_paid, description)
VALUES
    ('전일 연차', 1.0, false, true, '하루 종일 휴가 사용'),
    ('오전 반차', 0.5, false, true, '오전 근로 면제 (09:00~13:00)'),
    ('오후 반차', 0.5, false, true, '오후 근로 면제 (13:00~18:00)'),
    ('병가', 1.0, true, false, '질병 또는 부상 치료 (진단서 필수)'),
    ('공가', 0.0, true, true, '국가 건강검진, 투표, 교육 등'),
    ('경조사 휴가', 1.0, true, true, '본인 및 가족 경조사')
ON CONFLICT (name) DO NOTHING;

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
    substitute_id UUID REFERENCES public.profiles(id), -- 대체 근무 생활지원사
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    substitute_status TEXT NOT NULL DEFAULT 'pending' CHECK (substitute_status IN ('pending', 'accepted', 'rejected')),
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'manager_approved', 'final_approved', 'rejected')),
    reject_reason TEXT,
    document_url TEXT, -- 증빙 서류 (Supabase Storage URL)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ
);

-- 6. 신규 사용자 가입 시 프로필 & 연차 기본 생성 트리거
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, phone, role, zone_code, hire_date)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', '생활지원사'),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'worker'),
        COALESCE(NEW.raw_user_meta_data->>'zone_code', '1권역'),
        CURRENT_DATE
    );

    INSERT INTO public.leave_balances (user_id, year, total_days, used_days)
    VALUES (
        NEW.id,
        EXTRACT(YEAR FROM CURRENT_DATE)::INT,
        15.0,
        0.0
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 7. 휴가 최종 승인 시 연차 자동 차감 트리거
CREATE OR REPLACE FUNCTION public.handle_leave_approval()
RETURNS TRIGGER AS $$
DECLARE
    deduct_amount NUMERIC(3, 1);
    days_count INT;
    total_deduct NUMERIC(4, 1);
BEGIN
    -- 최종 승인(final_approved) 상태로 변경되었을 때만 차감
    IF NEW.status = 'final_approved' AND OLD.status != 'final_approved' THEN
        SELECT deduction_days INTO deduct_amount
        FROM public.leave_types
        WHERE id = NEW.leave_type_id;

        -- 날짜 수 계산 (종료일 - 시작일 + 1)
        days_count := (NEW.end_date - NEW.start_date) + 1;
        total_deduct := deduct_amount * days_count;

        -- 연차 차감
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

-- ========================================================
-- 🛡️ Row Level Security (RLS) 보안 정책
-- ========================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

-- 휴가 유형: 누구나 조회 가능
CREATE POLICY "leave_types_select_all" ON public.leave_types
    FOR SELECT TO authenticated USING (true);

-- 프로필: 모든 인증된 사용자가 기본 프로필 조회 가능 (대체 근무자 지정 목적 등)
CREATE POLICY "profiles_select_all" ON public.profiles
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "profiles_update_self" ON public.profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id);

-- 연차 잔여일수: 본인 것 조회 또는 관리자 전체 조회
CREATE POLICY "leave_balances_select" ON public.leave_balances
    FOR SELECT TO authenticated
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('manager', 'admin')
        )
    );

-- 휴가 신청:
-- 1) 조회: 본인 신청건, 본인이 대체자로 지정된 건, 또는 전담복지사/관리자
CREATE POLICY "leave_requests_select" ON public.leave_requests
    FOR SELECT TO authenticated
    USING (
        auth.uid() = user_id OR
        auth.uid() = substitute_id OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('manager', 'admin')
        )
    );

-- 2) 생성: 생활지원사 본인 휴가 신청
CREATE POLICY "leave_requests_insert" ON public.leave_requests
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- 3) 수정 (대체근무자 수락/거절 또는 관리자 승인/반려)
CREATE POLICY "leave_requests_update" ON public.leave_requests
    FOR UPDATE TO authenticated
    USING (
        auth.uid() = substitute_id OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('manager', 'admin')
        )
    );
