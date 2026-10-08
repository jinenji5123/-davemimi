/**
 * Supabase 클라이언트 초기화 모듈
 * 
 * 환경 변수 또는 브라우저 로컬스토리지에 저장된 설정값으로 Supabase 클라이언트를 초기화합니다.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// 1. 환경 변수 또는 localStorage에서 Supabase 연결 정보 가져오기
const getSupabaseConfig = () => {
    // Vite / Next.js 환경 변수 지원
    const envUrl = (typeof process !== 'undefined' && process.env?.NEXT_PUBLIC_SUPABASE_URL) 
        || (typeof import.meta !== 'undefined' && import.meta.env?.VITE_SUPABASE_URL);
    const envKey = (typeof process !== 'undefined' && process.env?.NEXT_PUBLIC_SUPABASE_ANON_KEY)
        || (typeof import.meta !== 'undefined' && import.meta.env?.VITE_SUPABASE_ANON_KEY);

    // 웹 브라우저 환경에서 직접 설정한 경우 (localStorage 지원)
    const localUrl = typeof window !== 'undefined' ? localStorage.getItem('SUPABASE_URL') : null;
    const localKey = typeof window !== 'undefined' ? localStorage.getItem('SUPABASE_ANON_KEY') : null;

    const supabaseUrl = envUrl || localUrl || '';
    const supabaseAnonKey = envKey || localKey || '';

    return { supabaseUrl, supabaseAnonKey };
};

const { supabaseUrl, supabaseAnonKey } = getSupabaseConfig();

// 2. Supabase 클라이언트 싱글톤 인스턴스 생성
export const supabase = (supabaseUrl && supabaseAnonKey) 
    ? createClient(supabaseUrl, supabaseAnonKey)
    : null;

/**
 * 런타임에서 Supabase 설정을 동적으로 업데이트하는 헬퍼 함수
 */
export const initSupabaseClient = (url, anonKey) => {
    if (typeof window !== 'undefined') {
        localStorage.setItem('SUPABASE_URL', url);
        localStorage.setItem('SUPABASE_ANON_KEY', anonKey);
    }
    return createClient(url, anonKey);
};
