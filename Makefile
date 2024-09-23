# Project Configuration
TARGET         = iphone:clang:16.5:14.0
FINALPACKAGE   = 1
PACKAGE_VERSION = 1.0

# Specify the desired architecture directly
ARCH          = arm64  # Change to desired architecture as needed
OBJ_PATH      = .theos/obj/arm64
DYLIB_PATH    = $(OBJ_PATH)/YTLitePlus.dylib

# Tweak Information
TWEAK_NAME    = YTLitePlus
BUNDLE_ID     = com.google.ios.youtube

# FLEX Headers
FLEX_HEADER_PATHS := $(shell find Tweaks/FLEX -name '*.h' -exec dirname {} \; | uniq)
EXTRA_CFLAGS := $(addprefix -I,$(FLEX_HEADER_PATHS)) -I$(THEOS_PROJECT_DIR)/Tweaks

# Source Files
YTLitePlus_FILES := \
    YTLitePlus.xm \
    $(shell find Source -name '*.xm' -o -name '*.x' -o -name '*.m') \
    $(shell find Tweaks/FLEX -type f \( -iname \*.c -o -iname \*.m -o -iname \*.mm \))

# Compilation and Linker Flags
YTLitePlus_CFLAGS := \
    -fobjc-arc \
    -Wno-deprecated-declarations \
    -Wno-unsupported-availability-guard \
    -Wno-unused-but-set-variable \
    -DTWEAK_VERSION=$(PACKAGE_VERSION) \
    $(EXTRA_CFLAGS)

YTLitePlus_LDFLAGS := \
    -F$(THEOS)/lib \
    $(filter-out -multiply_defined% -lc++, $(YTLitePlus_LDFLAGS))

# Libraries and Frameworks
YTLitePlus_LIBRARIES = substrate
YTLitePlus_FRAMEWORKS = UIKit Security

# Theos Setup
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

# Pre-build Hook
before-all::
	@echo "==> Preparing to build YTLitePlus..."
	@if [ ! -d "$(THEOS)" ]; then \
		echo "Error: THEOS environment not set up correctly."; \
		exit 1; \
	fi

# Pre-package Hook
before-package::
	@echo "==> Preparing resources..."
	@mkdir -p "$(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries"
	@if [ ! -f "$(DYLIB_PATH)" ]; then \
		echo "Error: YTLitePlus.dylib not found at '$(DYLIB_PATH)'. Please check the build."; \
		exit 1; \
	fi
	@cp "$(DYLIB_PATH)" "$(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/"
	@echo "==> YTLitePlus.dylib copied."

	@mkdir -p "$(THEOS_STAGING_DIR)/Library/Application Support/YTLitePlus.bundle"
	@if [ -d lang/YTLitePlus.bundle ]; then \
		cp -R lang/YTLitePlus.bundle/* "$(THEOS_STAGING_DIR)/Library/Application Support/YTLitePlus.bundle/"; \
		echo "==> YTLitePlus.bundle copied."; \
	else \
		echo "Warning: YTLitePlus.bundle not found, skipping."; \
	fi

	@cp YTLitePlus.plist "$(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/"

# Cleaning Hooks
clean::
	@echo "==> Cleaning resources..."
	@rm -rf Resources/*
	@echo "==> Clean-up finished."

# Enable verbose build output for debugging
export THEOS_BUILD_VERBOSE = 1