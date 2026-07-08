SWIFT ?= swift

# When only Command Line Tools are installed (no full Xcode), SwiftPM cannot
# locate the Swift Testing runtime, so fall back to explicit framework/rpath
# flags pointing at the toolchain's Frameworks directory.
DEVELOPER_DIR := $(shell xcode-select -p 2>/dev/null)
HAS_XCODE := $(shell [ -d "$(DEVELOPER_DIR)/../Applications/Xcode.app" ] || \
	[ "$(DEVELOPER_DIR)" != "/Library/Developer/CommandLineTools" ] && echo yes)
TEST_FLAGS := $(if $(HAS_XCODE),,\
	-Xswiftc -F -Xswiftc "$(DEVELOPER_DIR)/Library/Developer/Frameworks" \
	-Xlinker -rpath -Xlinker "$(DEVELOPER_DIR)/Library/Developer/Frameworks" \
	-Xlinker -rpath -Xlinker "$(DEVELOPER_DIR)/Library/Developer/usr/lib")

.PHONY: all build release run test app clean

all: build

## build: debug build
build:
	$(SWIFT) build

## release: release build
release:
	$(SWIFT) build -c release

## run: build and launch
run:
	$(SWIFT) run

## test: run the SizeEnforcerKitTests suite
test:
	$(SWIFT) test $(TEST_FLAGS)

## app: assemble ./build/SizeEnforcer.app (ad-hoc signed)
app:
	scripts/make-app.sh

## clean: remove build artifacts
clean:
	$(SWIFT) package clean
	rm -rf .build build
