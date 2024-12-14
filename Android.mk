#
# Copyright (C) 2023 Paranoid Android
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifneq ($(filter fuxi,$(TARGET_DEVICE)),)

include $(call all-makefiles-under,$(LOCAL_PATH))

include $(CLEAR_VARS)

WIFI_FIRMWARE_SYMLINKS := $(TARGET_OUT_VENDOR)/firmware/
$(WIFI_FIRMWARE_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating wifi firmware symlinks: $@"
	@mkdir -p $@/wlan/qca_cld/kiwi_v2
	$(hide) ln -sf /data/vendor/firmware/wlanmdsp.mbn $@/wlanmdsp.otaupdate
	$(hide) ln -sf /mnt/vendor/persist/kiwi_v2/wlan_mac.bin $@/wlan/qca_cld/kiwi_v2/wlan_mac.bin
	$(hide) ln -sf /vendor/etc/wifi/kiwi_v2/WCNSS_qcom_cfg.ini $@/wlan/qca_cld/kiwi_v2/WCNSS_qcom_cfg.ini

ALL_DEFAULT_INSTALLED_MODULES += $(WIFI_FIRMWARE_SYMLINKS)

endif
