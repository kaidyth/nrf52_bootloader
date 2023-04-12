# Kaidyth Bootloader

[![Build Status](https://drone.erianna.com/api/badges/kaidyth/nrf52_bootloader/status.svg)](https://drone.erianna.com/kaidyth/nrf52_bootloader)

A secure bluetooth DFU bootloader for nRF52 with support for the following boards:

- [nRF52840 MDK (Maker Diary)](https://wiki.makerdiary.com/nrf52840-mdk/)
- [nRF52840 MDK USB Dongle (Maker Diary)](https://wiki.makerdiary.com/nrf52840-mdk-usb-dongle/)
- [Nordic nRF52840DK PCA10056](https://www.nordicsemi.com/Software-and-Tools/Development-Kits/nRF52840-DK)
- [Nordic nRF52840DK PCA10059 ("Dongle")](https://www.nordicsemi.com/Software-and-Tools/Development-Kits/nRF52840-Dongle)
- [SparkFun Pro nRF52840](https://www.sparkfun.com/products/15025)
- [Adafruit nRF52840 Feather Express](https://www.adafruit.com/product/4062)
- [Particle Xenon](https://docs.particle.io/xenon/)
- [Pitaya Go](https://wiki.makerdiary.com/pitaya-go/)
- [Arduino Nano 33 BLE](https://store.arduino.cc/usa/nano-33-ble)

## Features

- Based on nRF52 Secure Bootloader
- DFU over BLE OTA + USB Serial
- Self Upgradable via OTA + USB Serial
- Optionally downgradable (`NRF_DFU_BL_ALLOW_DOWNGRADE` Makefile option)
- Double Reset DFU Trigger

### Planned Features

- Application Wipe via 2 Pin Reset
- Arduino BLE* (see below)

## Flashing

### Using Prebuilt Binaries

If you're just looking to flash the bootloader to your device, simply grab the appropriate board file from the Github releases page and flash using JLink/nrfjprog.

```bash
nrfjprog -f nrf52 --erase
nrfjprog -f nrf52 --program nrf52840_xxaa_s140_<board>.hex

# For PCA10059 reset UICR before resetting
nrfjprog --memwr 0x10001304 --val 0xFFFFFFFD

nrfjprog -f nf52 --reset
```

> Note that the default bootloader is distributed with a public keypair for application signing. This will permit anyone who has access to the key to be able to flash and overwrite any application you have while in OTA DFU mode. If you're using this bootloader in a production setting, it is recommended to build your own binary with your own keypair.

### Unsupported Boards

While this bootloader has a variety of officially supported boards, your specific board, module, or chip may not yet have a formal definition.

The generic variant can be built by running the following command.

```bash
make BOARD=generic clean_build
```

> The generic bootloader is distributed in `DEBUG` mode to aid in debugging and creating a formal definition. You are advised to create a formal production ready board definition for your variant before going into production.

### Building/Development

Cross platform builds are run through `Docker` to ensure build compatability, eliminate OS specific build issues, and ensure a functional build environment. Simply specify `DEBUG` and `BOARD` environment variables in `docker run` to build an appropriate build for your chip.

```bash
docker run -v${PWD-.}:/app --env BOARD=mdk-usb-dongle kaidyth/nrf52_toolchain:latest
```

> You can re-build the local container by running: `docker build . -t kaidyth_dfu/toolchain:latest`

Hex and .zip archives for DFU flashes are outputted to the `_build_<board>` directory after compilation succeeds.

> Note that patches the nRF52 SDK to to add some unoffocially supported functionality (such as `NRF_DFU_BL_ALLOW_DOWNGRADE` and `NRF_DFU_BL_ACCEPT_SAME_VERSION`). It's recommended to use the docker environment for building unless you plan on switching `NORDIC_SDK_PATH` between projects.

If you're interested in setting up your own development environment without docker, take a look at the [Getting Started](https://github.com/charlesportwoodii/kaidyth_nrf52_bootloader/wiki/Getting-Started) page for more information on the dependencies needed.

### Clock Support

Custom boards that do not have an external clock should define `BOARD_USE_SF_CLOCK` as part of the `make` command to utilize the onboard Soft Device LFCLK.

> If you are able to see your custom board, not get a `GATT ERROR` when attempting to connect it's likely this flag needs to be set.

### Arduino Support

This bootloader should compatible with Arduino Libraries excluding ones that interface with the Soft Device. Things such as I2C, GPIO, and Neopixels should work using their respective libaries, though I can't guarantee or provide support. Be sure to adjust your board linker settings and RAM regions to align with the Soft-Device version being used in the bootloader.

### Bluetooth / ArdinoBLE / Adarfruit NRF52 Bluefruit

The Nordic Secure Bootloader, and by proxy this bootloader do not officially support any operation that directly interfaces with the Soft Device, include Arduino BLE and Adafruit Bluefruit. If you want to use bluetooth functionality you are strongly encouraged to use the nRF5 SDK.
