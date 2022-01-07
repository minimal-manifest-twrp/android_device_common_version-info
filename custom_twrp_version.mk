#include this into the main BoardConfig for autogenerated CUSTOM_TWRP_VERSION
#do not echo anything back to stdout, seems to bork stuff -_-

#Version Defaults
ifeq ($(CUSTOM_TWRP_DEVICE_VERSION),)
CUSTOM_TWRP_DEVICE_VERSION =: 0
endif

ifeq ($(CUSTOM_TWRP_VERSION_PREFIX),)
CUSTOM_TWRP_VERSION_PREFIX =: LOCAL
endif

#if CUSTOM_TWRP_BUILD_NUMBER_FILE is not already defined, use the current path
ifeq ($(CUSTOM_TWRP_BUILD_NUMBER_FILE),)
# ${CURDIR}									full path to TOP
# $(dir $(lastword $(MAKEFILE_LIST)))		relative path to this file
CUSTOM_TWRP_BUILD_NUMBER_FILE := "$(dir $(lastword $(MAKEFILE_LIST)))CUSTOM_TWRP_BUILD_NUMBER-$(TARGET_DEVICE).txt"
endif

#Version info stored in device OUT folder
version_info_file := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/version-info.txt


#CUSTOM_TWRP_BUILD_NUMBER (later)
#line 0: TWRP version
#line 1: TWRP date
#line 2: TWRP build

#sub commands
cmd_put_out      := printf "%s-%02d" $$build_date $$build_num >$(CUSTOM_TWRP_BUILD_NUMBER_FILE);
cmd_get_out      := build_str=`cat $(CUSTOM_TWRP_BUILD_NUMBER_FILE)`; build_date=$${build_str:0:8}; build_num=$${build_str:9:2};
cmd_reset_ver    := echo -ne "\nCUSTOM_TWRP_VERSION.mk: New date, reset build number to 01\n\n" 1>&2; build_date=`date -u +%Y%m%d`; build_num=1;
cmd_incr_num     := build_num=$$(( 10\#$$build_num + 1 )); if [ $$build_num -gt 99 ]; then echo -ne "\nCUSTOM_TWRP_VERSION.mk: ERROR: Build number will exceed 99 resetting to 01\n\n" 1>&2; build_num=1; fi;
cmd_is_new_date  := `date -u +%Y%m%d` -gt $$build_date
cmd_main_ver     := `grep TW_MAIN_VERSION $(version_info_file) | cut -d '=' -f2`
cmd_device_ver   := `grep TW_DEVICE_VERSION $(version_info_file) | cut -d '=' -f2`


#run on envsetup and/or any make
cmd_pre_run  := if [ ! -f $(CUSTOM_TWRP_BUILD_NUMBER_FILE) ]; then
cmd_pre_run  += 	echo "CUSTOM_TWRP_VERSION.mk: Create TWRP Recovery build number file" 1>&2;
cmd_pre_run  += 	$(cmd_reset_ver)
cmd_pre_run  += 	$(cmd_put_out)
cmd_pre_run  += else
cmd_pre_run  += 	$(cmd_get_out)
cmd_pre_run  += 	if [ $(cmd_is_new_date) ]; then
cmd_pre_run  += 		$(cmd_reset_ver)
cmd_pre_run  += 		$(cmd_put_out)
cmd_pre_run  += 	fi;
cmd_pre_run  += fi;

#run after: make recovery(boot) image
cmd_post_run := $(cmd_get_out)
cmd_post_run += if [ $(cmd_is_new_date) ]; then
cmd_post_run += 	$(cmd_reset_ver)
cmd_post_run += else
cmd_post_run += 	$(cmd_incr_num)
cmd_post_run += fi;
cmd_post_run += $(cmd_put_out)

#rename recoveryimage command
cmd_ren_rec_img := echo -ne "\n\nCUSTOM_TWRP_VERSION.mk: Renaming output file...\n" 1>&2;
cmd_ren_rec_img += mv -v
cmd_ren_rec_img +=  "$(OUT_DIR)/target/product/$(TARGET_DEVICE)/recovery.img"
cmd_ren_rec_img +=  "$(OUT_DIR)/target/product/$(TARGET_DEVICE)/twrp-$(cmd_main_ver)-$(cmd_device_ver)-$(TARGET_DEVICE).img"
cmd_ren_rec_img +=  1>&2;

#rename bootimage command
cmd_ren_boot_img := echo -ne "\n\nCUSTOM_TWRP_VERSION.mk: Renaming output file...\n" 1>&2;
cmd_ren_boot_img += mv -v
cmd_ren_boot_img +=  "$(OUT_DIR)/target/product/$(TARGET_DEVICE)/boot.img"
cmd_ren_boot_img +=  "$(OUT_DIR)/target/product/$(TARGET_DEVICE)/twrp-$(cmd_main_ver)-$(cmd_device_ver)-$(TARGET_DEVICE).img"
cmd_ren_boot_img +=  1>&2;


#if the build number file doesnt exist create it as 01, if it does then check date
$(shell $(cmd_pre_run))

TW_MAIN_VERSION := $(shell echo "`sed -n -e 's/^.*#define TW_MAIN_VERSION_STR //p' bootable/recovery/variables.h | cut -d'"' -f 2`")
CUSTOM_TWRP_VERSION := $(shell cat $(CUSTOM_TWRP_BUILD_NUMBER_FILE))
TW_DEVICE_VERSION := $(CUSTOM_TWRP_DEVICE_VERSION)_$(CUSTOM_TWRP_VERSION_PREFIX)-$(CUSTOM_TWRP_VERSION)

$(shell echo "CUSTOM_TWRP_VERSION.mk: TWRP Recovery build number=$(CUSTOM_TWRP_VERSION)" 1>&2)

$(version_info_file):
	echo 'TW_MAIN_VERSION=$(TW_MAIN_VERSION)' > $@
	echo 'TW_DEVICE_VERSION=$(TW_DEVICE_VERSION)' >> $@

#once the image is built, rename the output file, and increase the build number for the next run
bootimage: $(version_info_file)
	$(shell $(cmd_ren_boot_img))
	$(shell $(cmd_post_run))
	$(shell echo "CUSTOM_TWRP_VERSION.mk: Increase TWRP Recovery build number to `cat $(CUSTOM_TWRP_BUILD_NUMBER_FILE)` for next build" 1>&2)

recoveryimage: $(version_info_file)
	$(shell $(cmd_ren_rec_img))
	$(shell $(cmd_post_run))
	$(shell echo "CUSTOM_TWRP_VERSION.mk: Increase TWRP Recovery build number to `cat $(CUSTOM_TWRP_BUILD_NUMBER_FILE)` for next build" 1>&2)

