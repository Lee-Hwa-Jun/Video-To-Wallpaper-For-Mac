# Video Wallpaper for Mac

mp4 · mov 등의 동영상(또는 mp3 같은 오디오 파일)을 **맥의 바탕화면 위에서 재생**해 주는 메뉴바 앱입니다.
바탕화면 아이콘 아래, 시스템 배경화면 위에 영상 창을 깔아 두는 방식으로 동작하며, 여러 대의 모니터를 각각 다르게 설정할 수 있습니다.

## 주요 기능

- **영상 배경화면**: macOS가 재생할 수 있는 모든 포맷(mp4, mov, m4v, HEVC 등) 지원. 오디오 파일을 넣으면 소리만 재생됩니다.
- **화면 맞춤 방식** (해상도·비율이 달라도 OK)
  - 화면 채우기 — 비율 유지, 넘치는 부분은 잘림 (기본값)
  - 화면에 맞추기 — 영상 전체가 보이고 남는 부분은 배경으로 채움
  - 가로 폭 기준 맞추기 / 세로 높이 기준 맞추기
  - 늘려서 채우기 — 비율 무시
- **회전**: 0° / 시계 90° / 180° / 반시계 90°. 세로 영상을 가로 모니터에 세워 보이거나, 세로로 세운 모니터에 맞출 때 사용합니다.
- **남는 부분 처리**: 검정 / 원하는 단색 / 영상을 흐리게 확대해서 채우기
- **재생 옵션**: 반복 재생(끊김 없는 루프), 소리 끄기·볼륨, 재생 속도(0.25x ~ 2x)
- **다중 모니터**: 모든 모니터에 같은 설정을 쓰거나, 모니터별로 영상·맞춤·회전을 따로 지정. 모니터를 꽂거나 뺄 때 자동으로 반영됩니다.
- **절전**: 다른 창(전체화면 앱 등)에 완전히 가려지면 자동 일시정지, 화면 잠자기 중에는 재생 중단. 배경 영상이 화면 잠자기를 막지 않습니다.
- **로그인 시 자동 실행**, 메뉴바에서 재생/일시정지, 파일 드래그 앤 드롭

## 요구 사항

- macOS 13 Ventura 이상 (Apple Silicon / Intel 모두 지원)
- 빌드 시: Xcode 15 이상 또는 Xcode Command Line Tools (`xcode-select --install`)

## 빌드 및 실행

```bash
git clone https://github.com/lee-hwa-jun/video-to-wallpaper-for-mac.git
cd video-to-wallpaper-for-mac

# 1) 앱 번들 만들기 → build/Video Wallpaper.app
make app

# 2) 실행
open "build/Video Wallpaper.app"

# (선택) /Applications 에 설치
make install
```

개발 중에는 `make run`(= `swift run VideoWallpaper`)으로 바로 실행할 수 있습니다. 단, 이 경우 `.app` 번들이 아니므로 "로그인 시 자동 실행" 옵션은 동작하지 않습니다.

GitHub Actions(`.github/workflows/build.yml`)가 push마다 macOS 러너에서 앱을 빌드하고 `Video-Wallpaper-macOS` 아티팩트(zip)로 올려 두므로, 직접 빌드하지 않고 Actions 탭에서 내려받아도 됩니다.

> **처음 실행 시 "확인되지 않은 개발자" 경고가 뜨면**: 앱을 우클릭 → 열기, 또는 `시스템 설정 → 개인정보 보호 및 보안`에서 "그래도 열기"를 누르세요. 개인 배포용 ad-hoc 서명만 되어 있기 때문입니다.

## 사용법

1. 앱을 실행하면 메뉴바에 ▶︎ 모양 아이콘이 생기고, 처음이라면 설정 창이 자동으로 열립니다.
2. **영상 파일 → 선택…** 으로 파일을 고르거나, 파일을 설정 창의 파일 영역에 끌어다 놓습니다.
3. **화면 맞춤**에서 맞춤 방식·회전·남는 부분 처리를 고르면 즉시 배경에 반영됩니다.
4. **재생**에서 반복·소리·속도를 조절합니다.
5. 모니터가 여러 대라면 **디스플레이 → 모니터마다 다른 설정 사용**을 켜고, 모니터를 골라 각각 설정합니다.
   "현재 모니터 설정을 모든 모니터에 적용" 버튼으로 한 모니터의 설정을 전체에 복사할 수 있습니다.

메뉴바 아이콘 메뉴에서는 설정 열기, 영상 열기(모든 모니터에 적용), 재생/일시정지, 종료를 할 수 있습니다.

## 프로젝트 구조

```
Package.swift                          Swift Package (실행 파일 타깃, macOS 13+)
Sources/VideoWallpaper/
  main.swift                           NSApplication 구동
  AppDelegate.swift                    앱 수명주기, 파일 열기 처리
  StatusBarController.swift            메뉴바 아이콘과 메뉴
  Models/
    Config.swift                       FitMode, Rotation, BackgroundStyle, DisplayConfig, AppConfig
    ConfigStore.swift                  UserDefaults 저장/복원 (JSON)
    DisplayInfo.swift                  모니터 식별(UUID), 모니터 목록 관찰
  Wallpaper/
    WallpaperManager.swift             모니터별 창 생성/정리, 설정·잠자기 반영
    WallpaperWindowController.swift    모니터 1대 = 창 1개 + 플레이어 1개, 가려짐 감지
    WallpaperWindow.swift              데스크톱 레벨의 테두리 없는 창
    WallpaperView.swift                맞춤 방식·회전·블러 배경 레이어 배치
    WallpaperPlayer.swift              AVQueuePlayer + AVPlayerLooper 재생 제어
  Settings/
    SettingsWindowController.swift     설정 창 (NSHostingController)
    SettingsView.swift                 SwiftUI 설정 화면
  Support/                             색상 hex 변환, 로그인 항목, 파일 선택 패널
Resources/Info.plist                   LSUIElement(메뉴바 전용) 등 번들 정보
Scripts/build-app.sh                   swift build 결과를 .app 으로 포장 + ad-hoc 서명
```

## 동작 원리

- 각 모니터마다 `NSWindow`를 `kCGDesktopWindowLevel + 1` 레벨, 테두리 없음, 마우스 이벤트 무시, 모든 Space에 표시되도록 만들어 화면 전체에 깔아 둡니다. 시스템 배경화면보다는 위, Finder의 바탕화면 아이콘보다는 아래에 위치합니다.
- 창 안에는 `AVPlayerLayer`를 배치하고, 맞춤 방식에 따라 `videoGravity`(aspectFill / aspect / resize)와 레이어 크기·회전(`CATransform3D`)을 계산합니다. 가로/세로 기준 맞춤은 영상의 원본 크기(`naturalSize` + `preferredTransform`)를 읽어 직접 배율을 계산합니다.
- "흐리게 확대해서 채우기"는 같은 플레이어를 공유하는 두 번째 `AVPlayerLayer`에 `CIGaussianBlur` 필터를 적용한 것입니다.
- 반복 재생은 `AVPlayerLooper`로 끊김 없이 처리하고, 창의 `occlusionState`를 관찰해 완전히 가려지면 재생을 멈춥니다.
- 모니터는 `CGDisplayCreateUUIDFromDisplayID`로 얻은 UUID로 식별하므로 케이블을 뽑았다 다시 꽂아도 설정이 유지됩니다.

## 알려진 제한

- 데스크톱 레벨 창 방식이므로 시스템 설정의 "배경화면" 항목에는 반영되지 않습니다. (로그인 화면, 미션 컨트롤 미리보기 등)
- 배경 영상은 GPU를 사용합니다. 노트북에서는 4K 영상보다 1080p 정도를 권장하며, "가려지면 일시정지" 옵션을 켜 두는 것이 좋습니다.
