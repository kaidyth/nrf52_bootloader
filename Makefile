SHELL := env PATH=$(PATH) /bin/bash

GIT_VERSION = $(shell git describe --dirty --always --tags)

BOARD?=
BOARD_LIST:=$(sort $(subst /,,$(subst boards/,,$(dir $(wildcard boards/*/)))))

default: check-env
ifneq ($(filter $(BOARD),$(BOARD_LIST)),)
	$(MAKE) merge -C boards/$(BOARD)/s140
else
	$(error Run `make` with a board specified: ($(BOARD_LIST)))
endif

all: check-env $(BOARD_LIST)

$(BOARD_LIST):
	$(MAKE) -C boards/$@/s140

flash: default
	$(MAKE) flash -C boards/$(BOARD)/s140

clean_build: clean
	$(MAKE) -C boards/$(BOARD)/s140 dfu_package

clean_flash: clean_build
	$(MAKE) -C boards/$(BOARD)/s140 erase flash

clean: check-env
ifneq ($(filter $(BOARD),$(BOARD_LIST)),)
	@cd boards/$(BOARD)/s140 && $(MAKE) clean
	@rm -rf $(BOARD).hex
	@rm -f $(BOARD)_s140.zip
	@rm -f debug_$(BOARD)_s140.zip
else
	@for board in $(BOARD_LIST); do \
		cd boards/$$board/s140 && $(MAKE) clean; \
		cd ../../..; \
	done
	@rm -f *.hex
	@rm -f *.zip
endif

.PHONY: check-env
check-env: dfu_public_key.c
ifndef NORDIC_SDK_PATH
	$(error NORDIC_SDK_PATH is not defined.)
endif

private.pem:
	echo y | nrfutil keys generate ./private.pem

dfu_public_key.c: private.pem
	nrfutil keys display --key pk --format code private.pem --out_file dfu_public_key.c