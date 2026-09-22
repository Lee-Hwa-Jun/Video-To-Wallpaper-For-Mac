.PHONY: build run app install clean

# 디버그 빌드
build:
	swift build

# 빌드 후 바로 실행 (메뉴바에 아이콘이 나타납니다)
run:
	swift run VideoWallpaper

# 릴리즈 빌드 + build/Video Wallpaper.app 생성
app:
	Scripts/build-app.sh release

# /Applications 에 설치
install: app
	rm -rf "/Applications/Video Wallpaper.app"
	cp -R "build/Video Wallpaper.app" /Applications/
	@echo "설치 완료: /Applications/Video Wallpaper.app"

clean:
	rm -rf .build build
