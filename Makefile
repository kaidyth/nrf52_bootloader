BOARD ?=
SOFTDEVICE ?=
BOARD_LIST := $(sort $(subst /,,$(subst boards/,,$(dir $(wildcard boards/*/)))))

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

default: check-env ## Builds the bootloaded for selected board
ifneq ($(filter $(BOARD),$(BOARD_LIST)),)
	$(MAKE) merge -C boards/$(SOFTDEVICE)/$(BOARD)
else
	$(error Run `make` with a board specified: ($(BOARD_LIST)))
endif

.PHONY: help
help:	## Lists all available commands and a brief description.
	@grep -E '^[a-zA-Z/_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: check-env $(BOARD_LIST) ## Builds the bootloader for all boards

$(BOARD_LIST): ## Builds the bootloader for the specified board
	$(MAKE) -C boards/$(SOFTDEVICE)/$@

flash: default ## Builds and flashes the bootloader over nrfjprog
	$(MAKE) flash -C boards/$(SOFTDEVICE)/$(BOARD)

clean_build: clean ## Builds and creates a DFU .zip package
	$(MAKE) -C boards/$(SOFTDEVICE)/$(BOARD) dfu_package

clean_flash: clean_build ## Performs a clean build and flashes it via jLink
	$(MAKE) -C boards/$(SOFTDEVICE)/$(BOARD) erase flash

usb_flash: check_port default ## Flashes the .zip over USB
	$(MAKE) -C boards/$(SOFTDEVICE)/$(BOARD) usb_flash

check_port:
ifndef PORT
	$(error PORT must be defined to perform usb serial flashing)
endif

clean: check-env patch ## Cleans the environment for the specified board
ifneq ($(filter $(BOARD),$(BOARD_LIST)),)
	@cd boards/$(SOFTDEVICE)/$(BOARD) && $(MAKE) clean
	@rm -rf $(BOARD).hex
	@rm -f $(BOARD)_$(SOFTDEVICE).zip
	@rm -f debug_$(BOARD)_$(SOFTDEVICE).zip
else
	@for board in $(BOARD_LIST); do \
		cd boards/$(SOFTDEVICE)/$$board && $(MAKE) clean; \
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

private.pem: ## Generates a new private key
	echo y | nrfutil keys generate ./private.pem

dfu_public_key.c: private.pem ## Generates a new public key from a generated private key
	nrfutil keys display --key pk --format code private.pem --out_file dfu_public_key.c

patch: ## Patches the files in the nordic SDK to support additional bootloader features
	@for file in $(subst ./sdk/,,$(call rwildcard,./sdk/,*.c)); do \
		if patch -p0 -s -f --dry-run --reject-file /dev/null $(NORDIC_SDK_PATH)/$${file} ./sdk/$${file}; then \
			patch --forward --unified $(NORDIC_SDK_PATH)/$${file} ./sdk/$${file}; \
		fi \
	done;
	@for file in $(subst ./sdk/,,$(call rwildcard,./sdk/,*/$(SOFTDEVICE)/nrf_bootloader.c)); do \
		echo "Copying $$file to $(NORDIC_SDK_PATH)/components/libraries/bootloader/nrf_bootloader.c"; \
		cp ./sdk/$$file $(NORDIC_SDK_PATH)/components/libraries/bootloader/nrf_bootloader.c; \
	done;
	@for file in $(subst ./sdk/,,$(call rwildcard,./sdk/,*nrf_dfu_validation.c)); do \
		echo "Copying $$file to $(NORDIC_SDK_PATH)/$${file#./sdk/}"; \
		cp ./sdk/$$file $(NORDIC_SDK_PATH)/$${file#./sdk/}; \
	done;

