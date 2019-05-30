#!/bin/bash

if [ -z "$(ls -A $HOME/gcc-arm-none-eabi-8-2018-q4-major)" ]; then
    cd $HOME
    wget https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/8-2018q4/gcc-arm-none-eabi-8-2018-q4-major-linux.tar.bz2
    tar -xf gcc-arm-none-eabi-8-2018-q4-major-linux.tar.bz2
    rm -rf gcc-arm-none-eabi-8-2018-q4-major-linux.tar.bz2
else
    echo "gcc-arm-none-eabi-8-2018-q4-major-linux is already installed."
fi

if [ -z "$(ls -A $HOME/nrf_sdk/15.3.0)" ]; then
    cd $HOME
    mkdir -p $HOME/nrf_sdk/15.3.0
    wget https://www.nordicsemi.com/-/media/Software-and-other-downloads/SDKs/nRF5/Binaries/nRF5SDK153059ac345.zip -O nRF5_SDK_15.3.0_59ac345.zip
    unzip nRF5_SDK_15.3.0_59ac345.zip > /dev/null 2>&1
    mv nRF5_SDK_15.3.0_59ac345/* $HOME/nrf_sdk/15.3.0
    rm -rf nRF5_SDK_15.3.0_59ac345.zip
    pwd
    ls -laht $HOME/nrf_sdk/15.3.0
else
    echo "nRF5 SDK is already installed."
fi

if [ -z "$(ls -A $HOME/nrf_sdk/15.3.0/external/micro-ecc/micro-ecc)" ]; then
    cd $HOME/nrf_sdk/15.3.0/external/micro-ecc/micro-ecc
    git clone https://github.com/kmackay/micro-ecc
    dos2unix $HOME/nrf_sdk/15.3.0/external/micro-ecc/micro-ecc/build_all.sh
    ./build_all.sh
else
    echo "MicroECC is already installed."
fi

if [ -z "$(ls -A $HOME/mergehex)" ]; then
    cd $HOME
    wget https://www.nordicsemi.com/api/sitecore/Products/DownloadPlatform --post-data=fileid=8F19D314130548209E75EFFADD9348DB -O cli-tools.tar
    tar -xf cli-tools.tar
else
    echo "nRF5 SDK CLI Tools is already installed."
fi