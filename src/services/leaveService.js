/**
 * 생활지원사 휴가관리 시스템 - Supabase 데이터베이스 서비스
 */

import { supabase } from '../lib/supabaseClient.js';

/**
 * 1. 휴가 유형 목록 조회 (연차, 반차, 병가 등)
 */
export async function getLeaveTypes(client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    const { data, error } = await client
        .from('leave_types')
        .select('*')
        .order('id', { ascending: true });

    if (error) throw error;
    return data;
}

/**
 * 2. 동료 생활지원사 목록 조회 (대체 근무자 지정용)
 */
export async function getColleagues(currentUserId, zoneCode = null, client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    let query = client
        .from('profiles')
        .select('id, name, phone, zone_code, role')
        .eq('role', 'worker');

    if (currentUserId) {
        query = query.neq('id', currentUserId);
    }
    if (zoneCode) {
        query = query.eq('zone_code', zoneCode);
    }

    const { data, error } = await query.order('name');
    if (error) throw error;
    return data;
}

/**
 * 3. 본인 연차 잔여일수 조회
 */
export async function getMyLeaveBalance(userId, year = new Date().getFullYear(), client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    const { data, error } = await client
        .from('leave_balances')
        .select('*')
        .eq('user_id', userId)
        .eq('year', year)
        .maybeSingle();

    if (error) throw error;
    return data || { total_days: 15, used_days: 0, remaining_days: 15 };
}

/**
 * 4. 휴가 신청서 제출
 */
export async function submitLeaveRequest({
    userId,
    leaveTypeId,
    substituteId,
    startDate,
    endDate,
    reason,
    documentUrl = null
}, client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    const { data, error } = await client
        .from('leave_requests')
        .insert([{
            user_id: userId,
            leave_type_id: leaveTypeId,
            substitute_id: substituteId || null,
            start_date: startDate,
            end_date: endDate,
            reason: reason,
            document_url: documentUrl,
            status: 'submitted',
            substitute_status: substituteId ? 'pending' : 'accepted'
        }])
        .select()
        .single();

    if (error) throw error;
    return data;
}

/**
 * 5. 내가 신청한 휴가 내역 조회
 */
export async function getMyLeaveRequests(userId, client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    const { data, error } = await client
        .from('leave_requests')
        .select(`
            *,
            leave_types (name, deduction_days, is_paid),
            substitute:profiles!leave_requests_substitute_id_fkey (name, phone)
        `)
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
}

/**
 * 6. 내가 대체 근무자로 지정된 요청 목록 조회
 */
export async function getAssignedSubstituteRequests(substituteUserId, client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    const { data, error } = await client
        .from('leave_requests')
        .select(`
            *,
            requester:profiles!leave_requests_user_id_fkey (name, phone, zone_code),
            leave_types (name)
        `)
        .eq('substitute_id', substituteUserId)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
}

/**
 * 7. 대체 근무 수락/거절 응답
 */
export async function respondSubstituteRequest(requestId, isAccepted, client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    const { data, error } = await client
        .from('leave_requests')
        .update({
            substitute_status: isAccepted ? 'accepted' : 'rejected'
        })
        .eq('id', requestId)
        .select()
        .single();

    if (error) throw error;
    return data;
}

/**
 * 8. [전담복지사/관리자용] 결재 대기 목록 조회
 */
export async function getPendingLeaveRequests(client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    const { data, error } = await client
        .from('leave_requests')
        .select(`
            *,
            requester:profiles!leave_requests_user_id_fkey (name, phone, zone_code),
            leave_types (name, deduction_days),
            substitute:profiles!leave_requests_substitute_id_fkey (name, phone)
        `)
        .in('status', ['submitted', 'manager_approved'])
        .order('start_date', { ascending: true });

    if (error) throw error;
    return data;
}

/**
 * 9. [관리자용] 휴가 최종 승인 또는 반려 처리
 */
export async function reviewLeaveRequest(requestId, newStatus, rejectReason = null, client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    const updatePayload = { status: newStatus };
    if (newStatus === 'rejected') {
        updatePayload.reject_reason = rejectReason;
    }

    const { data, error } = await client
        .from('leave_requests')
        .update(updatePayload)
        .eq('id', requestId)
        .select()
        .single();

    if (error) throw error;
    return data;
}

/**
 * 10. 권역별 휴가 캘린더 조회 (승인된 건 기준)
 */
export async function getCalendarLeaves(startDate, endDate, zoneCode = null, client = supabase) {
    if (!client) throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
    let query = client
        .from('leave_requests')
        .select(`
            id, start_date, end_date, reason, status,
            requester:profiles!leave_requests_user_id_fkey (name, zone_code),
            leave_types (name)
        `)
        .eq('status', 'final_approved')
        .gte('end_date', startDate)
        .lte('start_date', endDate);

    const { data, error } = await query;
    if (error) throw error;
    return data;
}
