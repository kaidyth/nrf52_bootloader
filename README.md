# Kaidyth Bootloader

A secure bluetooth DFU bootloader for nRF52 with support for the following boards:

- [nRF52840 MDK (Maker Diary)](https://wiki.makerdiary.com/nrf52840-mdk/)
- [nRF52840 MDK USB Dongle (Maker Diary)](https://wiki.makerdiary.com/nrf52840-mdk-usb-dongle/)
- [Nordic nRF52840DK PCA10056](https://www.nordicsemi.com/Software-and-Tools/Development-Kits/nRF52840-DK)
- [Nordic nRF52840DK PCA10059 ("Dongle")](https://www.nordicsemi.com/Software-and-Tools/Development-Kits/nRF52840-Dongle)
- [SparkFun Pro nRF52840](https://www.sparkfun.com/products/15025)

## Features

- DFU over BLE OTA
- Self Upgradable via OTA

### Planned Features

- DFU over Serial
- Self-Upgradable via USB
- Double Reset DFU Trigger
- Application Wipe via 2 Pin Reset
- DFU over Serial
- DFU using UF2
- Auto enter DFU briefly on startup for DTR auto-reset

## Flashing

### Using Prebuilt Binaries

If you're just looking to flash the bootloader to your device, simply grab the appropriate board file from the Github releases page and flash using JLink/nrfjprog.

```
nrfjprog -f nrf52 --erase
nrfjprog -f nrf52 --program nrf52840_xxaa_s140_<board>.hex

# For PCA10059 reset UICR before resetting
nrfjprog --memwr 0x10001304 --val 0xFFFFFFFD

nrfjprog -f nf52 --reset
```

> Note that the default bootloader is distributed with a public keypair for application signing. This will permit anyone who has access to the key to be able to flash and overwrite any application you have while in OTA DFU mode. If you're using this bootloader in a production setting, it is recommended to build your own binary with your own keypair.

### Building/Development

Take a look at the [Getting Started](https://github.com/charlesportwoodii/kaidyth_nrf52_bootloader/wiki/Getting-Started) page for more information on the dependencies needed.

With your dependencies installed you can compile the project for supported boards by running `make`

```
make BOARD=<board>
```

> Run `make` without a board specified to see a list of supported boards.

