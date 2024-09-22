# Define target and architectures
TARGET = iphone:clang:16.5:14.0
ARCHS = arm64 arm64e
MODULES = jailed
FINALPACKAGE = 1
PACKAGE_VERSION = 1.0

# Tweak-specific details
TWEAK_NAME = YTLitePlus
DISPLAY_NAME = YouTube
BUNDLE_ID = com.google.ios.youtube

# Set up FLEX header paths dynamically
FLEX_HEADER_PATHS := $(shell find Tweaks/FLEX -name '*.h' -exec dirname {} \; | uniq)
EXTRA_CFLAGS := $(addprefix -I,$(FLEX_HEADER_PATHS)) -I$(THEOS_PROJECT_DIR)/Tweaks

# Additional CFLAGS
export ADDITIONAL_CFLAGS = $(EXTRA_CFLAGS)

# Source files
YTLitePlus_FILES = \
    YTLitePlus.xm \
$(shell find Source -name '*.xm' -o -name '*.x' -o -name '*.m') \
$(shell find Tweaks/FLEX -type f \( -iname \*.c -o -iname \*.m -o -iname \*.mm \))

# Compiler flags and frameworks
YTLitePlus_CFLAGS = -fobjc-arc \
    -Wno-deprecated-declarations \
    -Wno-unsupported-availability-guard \
    -Wno-unused-but-set-variable \
    -DTWEAK_VERSION=$(PACKAGE_VERSION) \
$(EXTRA_CFLAGS)

# Ensure we link the correct Substrate library
YTLitePlus_LDFLAGS += -F$(SUBSTRATE)
YTLitePlus_LIBRARIES += substrate

# Remove obsolete flags and duplicates
YTLitePlus_LDFLAGS := $(filter-out -multiply_defined%,$(YTLitePlus_LDFLAGS))
YTLitePlus_LDFLAGS := $(filter-out -lc++,$(YTLitePlus_LDFLAGS))

YTLitePlus_FRAMEWORKS = UIKit Security

# Include Theos common and tweak makefiles
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

# Packaging settings
INSTALL_TARGET_PROCESSES = YouTube

# Pre-build step
before-all::
	@echo -e "==> \033[1mPreparing to build YTLitePlus...\033[0m"
	@if [ ! -d "$(THEOS)" ]; then \
        echo "\033[31mError: THEOS environment not set up correctly.\033[0m"; exit 1; \
    fi

# Before-package steps
before-package::
	@echo -e "==> \033[1mPreparing YTLitePlus.dylib and FLEX resources...\033[0m"

    # Ensure directory for dylib
	@mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries

    # Copy YTLitePlus.dylib
	@if [ -f .theos/obj/$(TWEAK_NAME).dylib ]; then \
        cp .theos/obj/$(TWEAK_NAME).dylib $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/; \
        echo "==> \033[32mYTLitePlus.dylib copied successfully.\033[0m"; \
    else \
        echo "\033[31mError: YTLitePlus.dylib not found.\033[0m"; exit 1; \
    fi

    # Copy YTLitePlus.bundle
	@echo -e "==> \033[1mMoving YTLitePlus.bundle to Application Support...\033[0m"
	@mkdir -p $(THEOS_STAGING_DIR)/Library/Application\ Support/YTLitePlus.bundle
	@if [ -d lang/YTLitePlus.bundle ]; then \
        cp -R lang/YTLitePlus.bundle/* $(THEOS_STAGING_DIR)/Library/Application\ Support/YTLitePlus.bundle/; \
        echo "==> \033[32mYTLitePlus.bundle copied successfully.\033[0m"; \
    else \
        echo "\033[33mWarning: YTLitePlus.bundle not found, skipping.\033[0m"; \
    fi

    # Copy YTLitePlus.plist (Filter file)
	@echo -e "==> \033[1mCopying YTLitePlus.plist to DynamicLibraries...\033[0m"
	@cp YTLitePlus.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/

# Clean-up resources after packaging
internal-clean::
	@echo "==> \033[1mCleaning resources...\033[0m"
	@rm -rf Resources/*

# Ensure clean directory structure during clean-up
clean::
	@$(MAKE) internal-clean
	@echo "==> \033[32mClean-up finished.\033[0m"
