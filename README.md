# 🌿 생활지원사 휴가관리 시스템 (CareLeave Manager)

> **노인맞춤돌봄서비스 수행기관 맞춤형 생활지원사 휴가 신청·승인 및 돌봄 공백 관리 솔루션**

---

## 📌 프로젝트 소개
**생활지원사 휴가관리 시스템**은 노인맞춤돌봄서비스 등 복지 현장에서 근무하는 생활지원사의 휴가(연차, 반차, 병가, 경조사 등) 신청과 전담사회복지사/관리자의 승인 프로세스를 일원화하고, 돌봄 공백 없는 대체 근무 지원을 돕기 위해 설계된 통합 근태·휴가 관리 플랫폼입니다.

---

## 🎯 도입 배경 및 목표
1. **수기/서면 신청 디지털화**: 종이 신청서나 메신저로 분산되던 휴가 신청 및 결재 절차를 단일 웹 플랫폼으로 표준화
2. **돌봄 공백(어르신 안전) 최소화**: 휴가 기간 중 담당 어르신에 대한 대체 지원 인력(동료 생활지원사 등) 지정 및 모니터링
3. **연차/잔여일수 자동 계산**: 입사일 및 근로기준법에 기반한 연차 자동 산정 및 잔여일수 실시간 투명 조회
4. **기관 일정 캘린더 공유**: 권역별 생활지원사 일정 중복 방지 및 기관 전체 휴가 현황 한눈에 파악

---

## ✨ 주요 기능

### 1. 생활지원사 (근로자용)
- **간편 휴가 신청**
  - 휴가 유형 선택: 연차, 오전반차, 오후반차, 병가, 공가, 경조사, 대체휴무 등
  - 휴가 일시(기간) 지정 및 사유 작성
  - **대체 지원자(동료 생활지원사) 지정**: 휴가 기간 동안 담당 어르신을 대신 돌볼 대체 근무자 매핑
- **휴가 현황 및 잔여일수 조회**
  - 총 부여일수, 사용일수, 잔여일수 실시간 대시보드
  - 신청 건별 진행 상태(대기 / 승인 / 반려) 확인
- **알림 기능**
  - 결재 결과(승인/반려) 실시간 알림 (카카오 알림톡/웹 푸시)

### 2. 전담사회복지사 / 관리자용
- **휴가 신청 결재 관리**
  - 대기 중인 휴가 신청 목록 조회 및 원클릭 승인/반려 (반려 사유 입력 기능)
  - 담당 권역별 어르신 돌봄 대체 계획 적정성 확인
- **통합 휴가 캘린더**
  - 권역/팀별 월간·주간 휴가 현황 시각화
  - 동일 날짜 다수 휴가 신청 시 서비스 공백 경고 표시
- **생활지원사 근태 & 연차 관리**
  - 입사일/회계연도 기준 연차 자동 부여 및 정산
  - 생활지원사별 연간 휴가 사용 대장 관리
  - 고용노동부/지자체 제출용 엑셀(Excel) 리포트 다운로드

---

## 🏗️ 시스템 아키텍처

```mermaid
flowchart TD
    subgraph Client ["프론트엔드 (사용자/관리자)"]
        UI_User["생활지원사 모바일/웹 UI"]
        UI_Admin["관리자 웹 대시보드"]
    end

    subgraph Server ["백엔드 API 서버"]
        Auth["인증/권한 모듈 (JWT)"]
        Leave["휴가 신청/결재 서비스"]
        Subst["대체돌봄 매핑 서비스"]
        Calc["연차 자동산정 엔진"]
        Notify["알림 발송 모듈"]
    end

    subgraph DB ["데이터베이스"]
        UserDB[("사용자/권역 정보")]
        LeaveDB[("휴가/결재 이력")]
        BalanceDB[("연차 잔여일수")]
    end

    UI_User --> Auth
    UI_Admin --> Auth
    Auth --> Leave
    Auth --> Subst
    Leave --> Calc
    Leave --> Notify
    Leave --> LeaveDB
    Subst --> UserDB
    Calc --> BalanceDB
```

---

## 🛠️ 기술 스택 (Tech Stack)

| 구분 | 기술 | 설명 |
| :--- | :--- | :--- |
| **Frontend** | React / Next.js, TypeScript, Tailwind CSS | 모바일 친화적 반응형 UI, 캘린더 라이브러리 |
| **Backend** | Node.js (NestJS) 또는 Python (FastAPI) | RESTful API 서버, 비즈니스 로직 처리 |
| **Database** | PostgreSQL / MySQL, Prisma / TypeORM | 관계형 데이터베이스 및 ORM |
| **Authentication** | JWT, OAuth 2.0 (카카오 간편로그인 지원) | 권한별 인가(생활지원사 / 전담복지사 / 기관관리자) |
| **Deployment** | Docker, Nginx, GitHub Actions (CI/CD) | 컨테이너 기반 자동 배포 환경 |

---

## 📊 데이터베이스 모델 개요 (ERD)

```mermaid
erDiagram
    USERS ||--o{ LEAVE_REQUESTS : "신청"
    USERS ||--o{ LEAVE_BALANCES : "보유"
    USERS ||--o{ LEAVE_REQUESTS : "대체지원자로 지정"
    LEAVE_TYPES ||--o{ LEAVE_REQUESTS : "구분"

    USERS {
        int id PK
        string name "이름"
        string phone "연락처"
        string role "직책(생활지원사/전담복지사/관리자)"
        string zone "담당권역/팀"
        date hire_date "입사일"
    }

    LEAVE_TYPES {
        int id PK
        string code "연차/반차/병가 등"
        float deduction_days "차감일수"
        boolean is_paid "유급 여부"
    }

    LEAVE_REQUESTS {
        int id PK
        int user_id FK "신청자"
        int leave_type_id FK "휴가종류"
        int substitute_user_id FK "대체근무자"
        date start_date "시작일"
        date end_date "종료일"
        string reason "사유"
        string status "대기/승인/반려"
        int approver_id FK "결재자"
    }

    LEAVE_BALANCES {
        int id PK
        int user_id FK
        int year "해당연도"
        float total_days "총 부여일수"
        float used_days "사용일수"
        float remaining_days "잔여일수"
    }
```

---

## 🚀 빠른 시작 가이드 (Quick Start)

### 1. 저장소 복제 (Clone)
```bash
git clone https://github.com/jinenji5123/-davemimi.git
cd -davemimi
```

### 2. 의존성 패키지 설치
```bash
# 패키지 설치 예시
npm install
```

### 3. 환경 변수 설정 (`.env`)
```env
DATABASE_URL="postgresql://user:password@localhost:5432/careleave"
JWT_SECRET="your-jwt-secret-key"
```

### 4. 로컬 개발 서버 실행
```bash
npm run dev
```

---

## 📅 개발 로드맵 (Roadmap)
- [x] 프로젝트 기획 및 기본 요구사항 정의
- [ ] 권한별 회원 체계 및 로그인(소셜/모바일 로그인) 구현
- [ ] 휴가 신청/승인 및 대체근무자 매핑 API 개발
- [ ] 실시간 통합 캘린더 뷰 (FullCalendar 기반) 구현
- [ ] 근로기준법 맞춤 연차 자동 계산 엔진 구현
- [ ] 지자체/보건복지부 점검용 엑셀 출력 기능
- [ ] 모바일 PWA 및 카카오 알림톡 연동

---

## 📄 라이선스
This project is licensed under the MIT License.
