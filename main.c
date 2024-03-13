/**
 * Copyright (c) 2016 - 2019, Nordic Semiconductor ASA
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form, except as embedded into a Nordic
 *    Semiconductor ASA integrated circuit in a product or a software update for
 *    such product, must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other
 *    materials provided with the distribution.
 *
 * 3. Neither the name of Nordic Semiconductor ASA nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * 4. This software, with or without modification, must only be used with a
 *    Nordic Semiconductor ASA integrated circuit.
 *
 * 5. Any software provided in binary form under this license must not be reverse
 *    engineered, decompiled, modified and/or disassembled.
 *
 * THIS SOFTWARE IS PROVIDED BY NORDIC SEMICONDUCTOR ASA "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NORDIC SEMICONDUCTOR ASA OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
/** @file
 *
 * @defgroup bootloader_secure_ble main.c
 * @{
 * @ingroup dfu_bootloader_api
 * @brief Bootloader project main file for secure DFU.
 *
 */

#include <stdint.h>
#include "boards.h"
#include "bsp.h"
#include "nrf_mbr.h"
#include "nrf_bootloader.h"
#include "nrf_bootloader_app_start.h"
#include "nrf_bootloader_dfu_timers.h"
#include "nrf_dfu.h"
#include "nrf_log.h"
#include "nrf_log_ctrl.h"
#include "nrf_log_default_backends.h"
#include "app_error.h"
#include "app_error_weak.h"
#include "nrf_bootloader_info.h"
#include "nrfx.h"
#include "app_timer.h"
#include "nrf_drv_clock.h"
#include "nrf_delay.h"
#include "nrf_power.h"

#define DFU_DBLRST_MAGIC                0x02fc3c0a
#define DFU_DBLRST_DELAY                500
#define DFU_DBLRST_MEMADDR              0x20002A90


uint32_t* dblrst_mem = ((uint32_t*) DFU_DBLRST_MEMADDR);


static void do_reset(void)
{
    NRF_LOG_FINAL_FLUSH();

#if NRF_MODULE_ENABLED(NRF_LOG_BACKEND_RTT)
    // To allow the buffer to be flushed by the host.
    nrf_delay_ms(500);
#endif

    nrf_delay_ms(NRF_BL_RESET_DELAY_MS);

    NVIC_SystemReset();
}


static void on_error(void)
{
    do_reset();
}


void app_error_handler(uint32_t error_code, uint32_t line_num, const uint8_t * p_file_name)
{
    NRF_LOG_ERROR("Kaidyth DFU: App Error Handler called: %s:%d", p_file_name, line_num);
    on_error();
}


void app_error_fault_handler(uint32_t id, uint32_t pc, uint32_t info)
{
    NRF_LOG_ERROR("Kaidyth DFU: Received a fault! id: 0x%08x, pc: 0x%08x, info: 0x%08x", id, pc, info);
    assert_info_t * p_info = (assert_info_t *) 0x2000FF50;
    NRF_LOG_ERROR("ASSERTION FAILED at %s:%u",
    p_info->p_file_name,
    p_info->line_num);
    on_error();
}


void app_error_handler_bare(uint32_t error_code)
{
    NRF_LOG_ERROR("Kaidyth DFU: Received an error: 0x%08x!", error_code);
    on_error();
}

/**
 * @brief Function notifies certain events in DFU process.
 */
static void dfu_observer(nrf_dfu_evt_type_t evt_type)
{
    switch (evt_type)
    {
        case NRF_DFU_EVT_DFU_FAILED:
        case NRF_DFU_EVT_DFU_ABORTED:
        case NRF_DFU_EVT_DFU_INITIALIZED:
			if (LEDS_NUMBER > 0) {
				bsp_indication_set(BSP_INDICATE_ADVERTISING_WHITELIST);
			}
            break;
        case NRF_DFU_EVT_TRANSPORT_ACTIVATED:
			if (LEDS_NUMBER > 0) {
				bsp_indication_set(BSP_INDICATE_ADVERTISING_WHITELIST);
			}
            break;
        case NRF_DFU_EVT_DFU_STARTED:
			if (LEDS_NUMBER > 0) {
				bsp_indication_set(BSP_INDICATE_BONDING);
			}
            break;
        case NRF_DFU_EVT_DFU_COMPLETED:
			if (LEDS_NUMBER > 1) {
				bsp_board_led_on(BSP_BOARD_LED_1);
			}
		break;
        default:
            break;
    }
}

/**@brief Setup timers */
static void timers_init(void)
{
    uint32_t err_code;
    err_code = app_timer_init();
    APP_ERROR_CHECK(err_code);

    NRF_LOG_DEBUG("Kaidyth DFU: Timers initialized");
}

/**@brief Setup board support */
static void kaidyth_bsp_init(void)
{
    if (LEDS_NUMBER > 0) {
        uint32_t err_code;
        err_code = bsp_init(BSP_INIT_LEDS, NULL);
        APP_ERROR_CHECK(err_code);
    }

    NRF_LOG_DEBUG("Kaidyth DFU: BSP initialized");
}


/**@brief Bootstrapping setup for custom functionality */
static void kaidyth_bootstrap(void)
{
    if (LEDS_NUMBER > 0) {
        bsp_board_init(BSP_INIT_LEDS);
    }

   // double_reset();
   //
	//button_pressed(BUTTON_DFU)
   // nrf_power_gpregret_set(BOOTLOADER_DFU_START);
   //avoid to enter into bootloader mode if the pin used is for wake up
   uint32_t reset_reason = 0;    
   reset_reason = NRF_POWER->RESETREAS; 
   //clear register 
   NRF_POWER->RESETREAS = NRF_POWER->RESETREAS;
    if (BUTTONS_NUMBER > 0 && ((reset_reason & 0x10000) != 0x10000))
    {
		nrf_gpio_cfg_input(BUTTON_1,BUTTON_PULL);
		nrf_delay_ms(50);
		if(nrf_gpio_pin_read(BUTTON_1) == BUTTONS_ACTIVE_STATE)
			nrf_power_gpregret_set(BOOTLOADER_DFU_START);
    }
    timers_init();
    kaidyth_bsp_init();
	if (LEDS_NUMBER > 2) {
		bsp_board_led_on(BSP_BOARD_LED_2);
    }
	
}

/**@brief Function for application main entry. */
int main(void)
{
    uint32_t ret_val;

    // Protect MBR and bootloader code from being overwritten.
    ret_val = nrf_bootloader_flash_protect(0, MBR_SIZE, false);
    APP_ERROR_CHECK(ret_val);
    ret_val = nrf_bootloader_flash_protect(BOOTLOADER_START_ADDR, BOOTLOADER_SIZE, false);
    APP_ERROR_CHECK(ret_val);

    (void) NRF_LOG_INIT(nrf_bootloader_dfu_timer_counter_get);
    NRF_LOG_DEFAULT_BACKENDS_INIT();

    NRF_LOG_INFO("Kaidyth DFU: Inside main");

    kaidyth_bootstrap();
	
	// Initiate the bootloader
	ret_val = nrf_bootloader_init(dfu_observer);
	APP_ERROR_CHECK(ret_val);

	// Either there was no DFU functionality enabled in this project or the DFU module detected
	// no ongoing DFU operation and found a valid main application.
	// Boot the main application.
	nrf_bootloader_app_start();

	// Should never be reached.
	NRF_LOG_INFO("Kaidyth DFU: After main");
}

/**
 * @}
 */
