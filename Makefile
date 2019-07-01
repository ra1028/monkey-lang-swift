build:
	swift build -c release

test:
	swift build
	swift test

generate-xcodeproj:
	swift package generate-xcodeproj

generate-linuxmain:
	swift test --generate-linuxmain
