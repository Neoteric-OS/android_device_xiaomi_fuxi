#
# Copyright (C) 2024 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from the Neoteric configuration.
$(call inherit-product, vendor/neoteric/target/product/neoteric-target.mk)

# Inherit from aurora device.
$(call inherit-product, device/xiaomi/fuxi/device.mk)

# Device identifier
PRODUCT_DEVICE := fuxi
PRODUCT_NAME := fuxi
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := Xiaomi 13
PRODUCT_MANUFACTURER := Xiaomi

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="fuxi_global-user 15 AQ3A.240912.001 OS2.0.207.0.VMCEUXM release-keys" \
    BuildFingerprint=Xiaomi/fuxi_global/fuxi:15/AQ3A.240912.001/OS2.0.207.0.VMCEUXM:user/release-keys \
    DeviceName=fuxi \
    DeviceProduct=fuxi \
    SystemDevice=fuxi \
    SystemName=fuxi

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi
