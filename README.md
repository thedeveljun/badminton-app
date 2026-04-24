배드민턴 클럽 관리 앱 (funminton_club_app)
모바일 최적화 + 에러 수정이 적용된 리팩토링 버전입니다.
📁 프로젝트 적용 방법
기존 프로젝트에서 `lib/` 폴더를 백업
이 zip의 `lib/` 폴더와 `pubspec.yaml`로 교체
터미널에서:
```bash
   flutter pub get
   flutter clean
   flutter run
   ```
⚠️ Android minSdk 설정 (중요!)
`flutter_tts` 사용을 위해 minSdkVersion 21+ 이 필요합니다.
`android/app/build.gradle.kts` 또는 `android/app/build.gradle` 파일을 열어 아래처럼 수정하세요:
```kotlin
android {
    defaultConfig {
        minSdk = 21   // 또는 flutter.minSdkVersion (SDK 21 이상이면 OK)
    }
}
```
🔧 주요 수정 사항
에러 수정
`main.dart` ↔ `app.dart` 의 클래스명 불일치 (`FunmintonApp` → `FunmintonClubApp`) 통일
누락되었던 `main_home_screen.dart` 신규 생성
중복 파일 정리 (scoreboard_page.dart, scoreboard_state.dart 등 2개 버전 → 1개로 통합)
`member_register_dialog.dart`의 `key: key` 오류 제거 (슈퍼 생성자 패턴 적용)
`withOpacity()` deprecated → `withValues(alpha:)`  전면 교체
누락되었던 `ScoreboardServeSetupResult`, `ScoreboardBulkPlayerEditResult`, `ScoreboardSavedMatchesPageResult` 모델 생성
엑셀 샘플 파일 assets에 없어도 코드로 자동 생성되도록 폴백 처리
모바일 최적화
AppBar 폰트 크기 17~18 (기존 과도한 크기 조정)
다이얼로그 내 폰트 13~18 범위로 통일
`FittedBox(fit: BoxFit.scaleDown)` 으로 작은 화면 overflow 방지
`Wrap` 사용으로 좁은 화면에서 버튼들이 자연스럽게 줄바꿈
`textScaler` 0.9~1.15 범위 제한 (시스템 글자 크기가 너무 크거나 작아도 앱 레이아웃 유지)
다이얼로그에 `keyboardDismissBehavior: onDrag` 적용 (키보드 제스처 해제)
`SafeArea` 적극 사용 (노치/홈 인디케이터 영역 보호)
홈화면 `LayoutBuilder`로 카드 aspect ratio 동적 계산
각 화면 `Scaffold` 구조 유지하면서 여백 축소
스코어보드 TTS
점수가 오를 때마다 한국어로 음성 안내
게임포인트, 듀스, 코트체인지 자동 안내
하단 볼륨 아이콘으로 TTS ON/OFF 토글
📦 폴더 구조
```
lib/
├── main.dart
├── app.dart
├── core/theme/
│   ├── app_colors.dart
│   └── text_styles.dart
└── features/
    ├── home/           # 홈 화면
    ├── members/        # 회원관리
    ├── finance/        # 재정관리
    ├── tournament/     # 대진표
    ├── scoreboard/     # 점수판
    └── event/          # 이벤트 (준비 중)
```
🎨 테마
메인 컬러: `#1E5DB8` (시드 컬러)
배경: `#F6F7FA`
폰트: Pretendard (시스템 폰트로 자동 폴백)
🐛 알려진 주의사항
`image_picker`, `google_mlkit_text_recognition`, `flutter_tts` 는 실기기에서만 온전히 동작합니다. 에뮬레이터에서는 일부 기능이 제한될 수 있습니다.
iOS 빌드 시 `Podfile` 의 platform 을 12.0 이상으로 설정하세요.