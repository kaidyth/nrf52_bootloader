FROM ubuntu:20.04
LABEL maintainer="Charles R. Portwood II <charlesportwoodii@erianna.com>"

ENV GNU_INSTALL_ROOT="/root/gcc-arm-none-eabi-8-2018-q4-major/bin/"
ENV NORDIC_SDK_PATH="/root/nrf_sdk/15.3.0"
ENV PATH="$PATH:/root/gcc-arm-none-eabi-8-2018-q4-major/bin:/root/nrf-command-line-tools/bin:/root/.local/bin"

ENV BOARD=""
ENV SOFTDEVICE=""
ENV DEBUG=0
ENV NRF_DFU_BL_ACCEPT_SAME_VERSION=1
ENV NRF_DFU_REQUIRE_SIGNED_APP_UPDATE=1
ENV NRF_BL_APP_SIGNATURE_CHECK_REQUIRED=0
ENV NRF_DFU_BLE_ADV_NAME="KAIDYTH_DFU"
ENV NRF_SDH_CLOCK_LF_SRC=0
ENV NRF_SDH_CLOCK_LF_RC_CTIV=0
ENV NRF_SDH_CLOCK_LF_RC_TEMP_CTIV=0


VOLUME [ "/app" ]

# Install apt dependencies
RUN apt update -qq && \
    apt install git unzip wget curl make build-essential dos2unix python python3-pip -y --no-install-recommends && \
    apt-get clean

# Install nrf52 SDK
RUN pip3 install --user nrfutil

# Install GCC ARM
ENV GCC_ARM_NAME_BZ="gcc-arm-none-eabi-8-2018-q4-major-linux.tar.bz2"
RUN cd $HOME && \
    curl -L "https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/8-2018q4/gcc-arm-none-eabi-8-2018-q4-major-linux.tar.bz2" -o ${GCC_ARM_NAME_BZ} && \
    tar -xf ${GCC_ARM_NAME_BZ} && \
    rm -rf ${GCC_ARM_NAME_BZ} 

# Install NRF Command Line Tools
RUN cd $HOME && \
    curl -L https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/10-15-4/nrf-command-line-tools-10.15.4_Linux-amd64.tar.gz -o cli-tools.tar.gz && \
    tar -xf cli-tools.tar.gz

# Install NRF SDK
RUN cd $HOME && \
        mkdir -p $HOME/nrf_sdk/15.3.0 && \
        wget https://www.nordicsemi.com/-/media/Software-and-other-downloads/SDKs/nRF5/Binaries/nRF5SDK153059ac345.zip -O nRF5_SDK_15.3.0_59ac345.zip && \
        mv nRF5_SDK_15.3.0_59ac345.zip $HOME/nrf_sdk/15.3.0 && \
        cd $HOME/nrf_sdk/15.3.0 && \
        unzip nRF5_SDK_15.3.0_59ac345.zip > /dev/null 2>&1 && \
        rm -rf nRF5_SDK_15.3.0_59ac345.zip && \
		mv nRF5_SDK_15.3.0_59ac345/* . && \
		rm -rf nRF5_SDK_15.3.0_59ac345

# Install micro-ecc
RUN cd $HOME/nrf_sdk/15.3.0/external/micro-ecc && \
    git clone https://github.com/kmackay/micro-ecc && \
    chmod +x $HOME/nrf_sdk/15.3.0/external/micro-ecc/build_all.sh && \
    dos2unix $HOME/nrf_sdk/15.3.0/external/micro-ecc/build_all.sh && \
    ls -laht $HOME/nrf_sdk/15.3.0/external/micro-ecc/micro-ecc && \
    ./build_all.sh

# Install
WORKDIR /app

CMD ["make", "clean_build"]