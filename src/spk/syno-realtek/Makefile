SPK_NAME = syno-realtek
SPK_VERS = 1.0
SPK_REV = 1
SPK_ICON = src/$(SPK_NAME).png

DEPENDS = 

include ../../mk/spksrc.common.mk
ifneq ($(findstring $(ARCH),$(x64_ARCHS)),$(ARCH))
UNSUPPORTED_ARCHS = $(ARCH)
endif

MAINTAINER = RROrg/wjz304
DESCRIPTION = "Realtek usb netcard driver for Synology NAS"
CHANGELOG = "1. Support Realtek r815[2,3,5,6,7,a]"

HOMEPAGE = https://www.kernel.org/
LICENSE  = GPLv2

SPK_DEPENDS = 

WIZARDS_DIR = src/wizard

STARTABLE = yes
SERVICE_USER = auto
SERVICE_SETUP = src/service-setup.sh

COPY_TARGET = nop
STRIP_TARGET = nop
POST_STRIP_TARGET = syno-realtek_strip_target

include ../../mk/spksrc.spk.mk

.PHONY: syno-realtek_strip_target
syno-realtek_strip_target:
	install -m 755 -d $(STAGING_DIR)/firmware/
	cp -r src/firmware/* $(STAGING_DIR)/firmware/
	install -m 755 -d $(STAGING_DIR)/modules/
	cp -r src/modules/* $(STAGING_DIR)/modules/
	install -m 755 -d $(STAGING_DIR)/udev/
	cp -r src/udev/* $(STAGING_DIR)/udev/
	find $(STAGING_DIR) -type d -exec chmod 755 {} \;
	find $(STAGING_DIR) -type f -exec chmod 644 {} \;
	find $(STAGING_DIR)/udev -type f -name "*.sh" -exec chmod 755 {} \;