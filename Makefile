APP := build/TCCPreflight.app
.PHONY: all build sign test typecheck install clean
all: build sign
build:
	cd helper && swift build -c release
	mkdir -p $(APP)/Contents/MacOS
	cp helper/.build/release/TCCPreflightHelper $(APP)/Contents/MacOS/tcc-preflight-helper
	cp helper/Resources/Info.plist $(APP)/Contents/Info.plist
sign:
	bash scripts/codesign.sh
test:
	bash tests/run.sh
typecheck:
	swiftc -typecheck helper/Sources/TCCPreflightHelper/*.swift
install: all
	@echo "Keep the repo at a fixed path; grants are tied to $(abspath $(APP)) and its signature."
	ln -sf $(abspath bin/tcc-preflight) /usr/local/bin/tcc-preflight
clean:
	rm -rf build helper/.build
