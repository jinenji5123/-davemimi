# 🌿 생활지원사 휴가관리 시스템 (CareLeave Manager)

> **노인맞춤돌봄서비스 수행기관 맞춤형 생활지원사 근태·휴가 관리 및 돌봄 공백 방지 솔루션**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-18.x+-green.svg)](https://nodejs.org/)
[![Next.js](https://img.shields.io/badge/Next.js-14.x-black.svg)](https://nextjs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15.x-blue.svg)](https://www.postgresql.org/)

---

## 📌 목차
1. [프로젝트 소개](#-프로젝트-소개)
2. [도입 배경 및 기대 효과](#-도입-배경-및-기대-효과)
3. [업무 결재 프로세스](#-업무-결재-프로세스)
4. [권한별 주요 기능](#-권한별-주요-기능)
5. [노인돌봄 현장 맞춤 휴가 정책](#-노인돌봄-현장-맞춤-휴가-정책)
6. [시스템 아키텍처](#-시스템-아키텍처)
7. [데이터베이스 모델 (ERD)](#-데이터베이스-모델-erd)
8. [핵심 API 엔드포인트](#-핵심-api-엔드포인트)
9. [디렉토리 구조](#-디렉토리-구조)
10. [빠른 시작 가이드](#-빠른-시작-가이드)
11. [개발 로드맵](#-개발-로드맵)

---

## 📌 프로젝트 소개
**생활지원사 휴가관리 시스템(CareLeave Manager)**은 전국의 노인맞춤돌봄서비스 수행기관 및 복지관에서 근무하는 **생활지원사**의 휴가(연차, 반차, 병가, 경조사 등) 신청과 **전담사회복지사·기관장**의 결재 승인 프로세스를 일원화한 복지 특화 ERP 솔루션입니다.

특히, 생활지원사 휴가 시 발생할 수 있는 **취약계층 어르신 돌봄 공백**을 사전에 방지하기 위해 **대체 근무자(동료 생활지원사) 매핑 기능**과 **권역별 일정 통합 캘린더**를 핵심으로 제공합니다.

---

## 🎯 도입 배경 및 기대 효과

| 기존 수기/서면 방식의 문제점 | 시스템 도입 후 개선 효과 |
| :--- | :--- |
| 종이 신청서 작성 및 대면 결재로 인한 행정 비효율 | **모바일 원클릭 신청 & 실시간 모바일 결재**로 행정 소요 시간 80% 단축 |
| 휴가 시 담당 어르신 대체 돌봄 인계 누락 위험 | **대체 근무자 사전 지정 및 동의 프로세스 의무화**로 안전 공백 차단 |
| 메신저, 구두 소통으로 인한 권역 내 휴가 일정 중복 | **권역별 통합 캘린더**를 통해 중복 신청 사전 감지 및 서비스 공백 경고 |
| 매월/연말 연차 정산 및 점검 시 수기 계산 오류 발생 | 근로기준법 기준 **연차 자동 산정 엔진 및 지자체 보고용 엑셀 즉시 추출** |

---

## 🔄 업무 결재 프로세스

```mermaid
sequenceDiagram
    autonumber
    actor W as 생활지원사 (신청자)
    actor S as 대체근무자 (동료)
    actor M as 전담사회복지사 (1차 검토)
    actor A as 기관장/관리자 (최종 결재)
    participant Sys as 휴가관리 시스템

    W->>Sys: 휴가 신청 (일정, 사유, 대체자 지정)
    Sys-->>S: 대체 근무 확인 요청 알림 발송
    S->>Sys: 대체 근무 수락 및 일정 확인
    Sys-->>M: 결재 대기 알림 (어르신 돌봄 계획 포함)
    M->>Sys: 1차 검토 및 승인 (권역 공백 여부 확인)
    Sys-->>A: 최종 결재 상신
    A->>Sys: 최종 승인 처리
    Sys->>Sys: 연차 잔여일수 자동 차감 & 캘린더 일정 등록
    Sys-->>W: 승인 완료 알림 발송 (카카오 알림톡/웹 푸시)
    Sys-->>S: 대체 근무 일정 최종 확정 안내
```

---

## 👥 권한별 주요 기능

### 1. 생활지원사용 (Mobile-First UI)
- **간편 휴가 신청**:
  - 전일 연차, 오전/오후 반차, 병가, 공가, 경조사 선택
  - 담당 어르신 대체 관리자(동료 생활지원사) 1:1 매핑
  - 증빙 서류 간편 첨부 (병가 진단서, 청첩장, 부고장 사진 촬영 업로드)
- **실시간 대시보드**:
  - 당해 연도 총 연차 / 사용 연차 / 잔여 연차 실시간 확인
  - 내 신청 내역 상태(대기 / 1차승인 / 최종승인 / 반려) 조회
- **대체 근무 요청 관리**:
  - 동료 생활지원사로부터 요청받은 대체 돌봄 요청 수락/거절

### 2. 전담사회복지사용 (Admin Web)
- **권역별 결재 승인 관리**:
  - 신청 건별 돌봄 대체 계획 적합성 검토 및 원클릭 승인/반려 (반려 사유 입력)
- **권역 통합 캘린더**:
  - 팀/권역별 생활지원사 휴가 및 대체근무 현황을 색상별로 시각화
  - 동일 날짜 다수 휴가 시 돌봄 공백 경고 알림(배지) 제공
- **대체 돌봄 관리**:
  - 대체자가 지정되지 않은 비상 상황 시 전담복지사 직접 돌봄 투입 배정

### 3. 기관장 / 총괄 관리자용
- **최종 결재 및 기관 통계**:
  - 기관 전체 휴가 결재 최종 승인
  - 월별/분기별 연차 소진율 및 복지관 인력 가동률 대시보드
- **정부/지자체 점검 지원**:
  - 노인맞춤돌봄서비스 지자체 감사용 근태 대장 엑셀(.xlsx) 즉시 다운로드

---

## 📋 노인돌봄 현장 맞춤 휴가 정책

| 구분 | 휴가 유형 | 차감 일수 | 증빙 필요 여부 | 비고 |
| :---: | :---: | :---: | :---: | :--- |
| **연차** | 전일 연차 | 1.0일 | 불필요 | 근무시간(5시간/일 등) 기준 차감 |
| **반차** | 오전/오후 반차 | 0.5일 | 불필요 | 오전(09:00~11:30) / 오후(12:30~15:00) 등 |
| **병가** | 유급/무급 병가 | 규정 준용 | 필수 | 진단서 또는 진료확인서 첨부 |
| **공가** | 법정 공가 | 0.0일 (유급) | 필수 | 국가건강검진, 투표, 예비군/민방위 |
| **경조사** | 특별 경조휴가 | 1~5일 (유급) | 필수 | 본인 결혼, 직계존비속 경조사 규정 |

---

## 🏗️ 시스템 아키텍처

```mermaid
flowchart TD
    subgraph ClientLayer ["프론트엔드 (Next.js 14)"]
        MobileClient["📱 생활지원사용 모바일 Web/PWA"]
        AdminClient["💻 전담복지사/관리자 통합 대시보드"]
    end

    subgraph APILayer ["백엔드 서비스 (NestJS / Node.js)"]
        AuthService["🔐 인증/인가 (JWT & RBAC)"]
        LeaveService["📄 휴가 신청/결재 엔진"]
        SubstituteService["🤝 대체돌봄 매핑 모듈"]
        CalendarService["📅 일정 및 캘린더 서비스"]
        ReportService["📊 엑셀 리포트/통계 엔진"]
        NotificationService["🔔 카카오 알림톡/웹 푸시"]
    end

    subgraph StorageLayer ["데이터 저장소"]
        DB[("PostgreSQL\n(메인 데이터베이스)")]
        FileStore[("S3 / 로컬 스토리지\n(증빙서류 첨부)")]
        RedisCache[("Redis\n(세션 및 실시간 캐시)")]
    end

    MobileClient -->|HTTPS / REST API| APILayer
    AdminClient -->|HTTPS / REST API| APILayer
    APILayer --> DB
    APILayer --> FileStore
    APILayer --> RedisCache
```

---

## 📊 데이터베이스 모델 (ERD)

```mermaid
erDiagram
    USERS ||--o{ LEAVE_REQUESTS : "신청"
    USERS ||--o{ LEAVE_BALANCES : "보유"
    USERS ||--o{ LEAVE_REQUESTS : "대체근무자"
    LEAVE_TYPES ||--o{ LEAVE_REQUESTS : "분류"
    LEAVE_REQUESTS ||--o{ ATTACHMENTS : "증빙첨부"

    USERS {
        bigint id PK
        string email UK
        string name "생활지원사 성명"
        string phone "연락처"
        enum role "ROLE_WORKER, ROLE_MANAGER, ROLE_ADMIN"
        string zone_code "담당권역 (예: 1권역, 2권역)"
        date hire_date "입사일"
        boolean is_active "재직 상태"
    }

    LEAVE_TYPES {
        int id PK
        string name "연차, 오전반차, 병가 등"
        float deduction "차감 일수 (1.0, 0.5 등)"
        boolean requires_document "증빙서류 필수 여부"
        boolean is_paid "유급 여부"
    }

    LEAVE_REQUESTS {
        bigint id PK
        bigint user_id FK "신청 직원"
        int leave_type_id FK "휴가 유형"
        bigint substitute_id FK "대체 근무자"
        date start_date "휴가 시작일"
        date end_date "휴가 종료일"
        string reason "휴가 사유"
        enum substitute_status "대기/수락/거절"
        enum status "신청/1차승인/최종승인/반려"
        text reject_reason "반려 사유"
        datetime approved_at "최종 승인 일시"
    }

    LEAVE_BALANCES {
        bigint id PK
        bigint user_id FK
        int year "기준 연도"
        float total_days "총 부여일수"
        float used_days "사용일수"
        float remaining_days "잔여일수"
    }

    ATTACHMENTS {
        bigint id PK
        bigint request_id FK
        string original_name "파일명"
        string file_path "저장 경로"
        bigint file_size "파일 크기"
    }
```

---

## 🔌 핵심 API 엔드포인트

| Method | Endpoint | 설명 | 대상 권한 |
| :---: | :--- | :--- | :---: |
| `POST` | `/api/v1/auth/login` | 휴대폰/사번 기반 로그인 및 JWT 발급 | 전체 |
| `GET` | `/api/v1/leaves/balance/my` | 본인 연차 잔여일수 및 사용 통계 조회 | 생활지원사 |
| `POST` | `/api/v1/leaves/request` | 휴가 신청서 작성 및 대체자 지정 | 생활지원사 |
| `PATCH` | `/api/v1/leaves/:id/substitute` | 대체 근무 수락/거절 응답 | 대체근무자 |
| `GET` | `/api/v1/manager/leaves/pending` | 소속 권역 결재 대기 목록 조회 | 전담복지사 |
| `POST` | `/api/v1/manager/leaves/:id/review` | 1차 검토 및 승인/반려 처리 | 전담복지사 |
| `POST` | `/api/v1/admin/leaves/:id/approve` | 기관장 최종 결재 승인 | 총괄관리자 |
| `GET` | `/api/v1/calendar/zone/:zoneCode` | 권역별 통합 휴가 캘린더 조회 | 전담복지사/관리자 |
| `GET` | `/api/v1/reports/annual/excel` | 연간 근태 대장 엑셀 파일 다운로드 | 총괄관리자 |

---

## 📁 디렉토리 구조

```text
careleave-manager/
├── client/                     # Next.js 14 프론트엔드
│   ├── src/
│   │   ├── app/                # App Router (페이지 라우팅)
│   │   │   ├── (worker)/       # 생활지원사용 모바일 뷰
│   │   │   └── (admin)/        # 전담사회복지사/관리자 뷰
│   │   ├── components/         # 캘린더, 결재 모달, 카드 UI 컴포넌트
│   │   ├── hooks/              # 커스텀 React 훅
│   │   └── lib/                # API 클라이언트 및 유틸 함수
│   └── public/
├── server/                     # NestJS 백엔드 API
│   ├── src/
│   │   ├── auth/               # 로그인, JWT 발급, RBAC 가드
│   │   ├── leaves/             # 휴가 신청 및 결재 비즈니스 로직
│   │   ├── calendar/           # 캘린더 조회 및 일정 충돌 검증
│   │   ├── users/              # 사용자 및 권역 관리
│   │   └── reports/            # 엑셀 보고서 생성 모듈
│   └── test/
├── prisma/                     # 데이터베이스 스키마 & 마이그레이션
└── README.md
```

---

## 🚀 빠른 시작 가이드 (Quick Start)

### 1. 저장소 클론
```bash
git clone https://github.com/jinenji5123/-davemimi.git
cd -davemimi
```

### 2. 환경 변수 설정
```bash
cp .env.example .env
```
```env
PORT=4000
DATABASE_URL="postgresql://postgres:password@localhost:5432/careleave_db?schema=public"
JWT_SECRET="your-super-secret-jwt-key"
KAKAO_ALIMTALK_API_KEY="your-kakao-api-key"
```

### 3. 패키지 설치 및 DB 마이그레이션
```bash
npm install
npx prisma migrate dev --name init
```

### 4. 로컬 개발 서버 구동
```bash
# 프론트엔드 & 백엔드 동시 실행
npm run dev
```

---

## 📅 개발 로드맵 (Roadmap)
- [x] 프로젝트 기획 및 상세 기능 명세서 완성
- [x] 복지 현장 맞춤형 DB 스키마(ERD) 및 결재 흐름 설계
- [ ] Next.js 기반 반응형 UI 및 생활지원사 간편 신청 폼 구현
- [ ] 전담사회복지사용 권역별 통합 캘린더 (FullCalendar 연동)
- [ ] 카카오 알림톡 API 연동 (휴가 결재 단계별 실시간 알림)
- [ ] 지자체/보건복지부 평가 대비 연차 대장 엑셀 출력 엔진 개발
- [ ] 모바일 홈 화면 바로가기(PWA) 지원

---

## 📄 라이선스 (License)
본 프로젝트는 [MIT 라이선스](LICENSE)에 따라 자유롭게 이용 및 수정이 가능합니다.
