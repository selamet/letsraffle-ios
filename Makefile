SIM ?= iPhone 17 Pro
DEST = platform=iOS Simulator,name=$(SIM)

.PHONY: generate build test open

generate:
	xcodegen generate

build: generate
	xcodebuild -project LetsRaffle.xcodeproj -scheme LetsRaffle -destination '$(DEST)' build CODE_SIGNING_ALLOWED=NO | xcbeautify 2>/dev/null || xcodebuild -project LetsRaffle.xcodeproj -scheme LetsRaffle -destination '$(DEST)' build CODE_SIGNING_ALLOWED=NO -quiet

test: generate
	xcodebuild -project LetsRaffle.xcodeproj -scheme LetsRaffle -destination '$(DEST)' test CODE_SIGNING_ALLOWED=NO -quiet

open: generate
	open LetsRaffle.xcodeproj
