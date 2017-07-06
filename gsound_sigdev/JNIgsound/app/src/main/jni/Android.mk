LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := PCMRender
LOCAL_SRC_FILES := gsound.c PCMRender.c

include $(BUILD_SHARED_LIBRARY)