#pragma once

#include <stdint.h>
#include <time.h>
#include "osdconfig.h"

typedef struct {
        uint32_t received_packet_cnt;
        uint32_t wrong_crc_cnt;
        int8_t current_signal_dbm;
	int8_t type;
	int signal_good;
} wifi_adapter_rx_status_t;

typedef struct {
        uint32_t received_packet_cnt;
        uint32_t wrong_crc_cnt;
        int8_t current_signal_dbm;
	int8_t type;
	int signal_good;
} wifi_adapter_rx_status_t_osd;

typedef struct {
        uint32_t received_packet_cnt;
        uint32_t wrong_crc_cnt;
        int8_t current_signal_dbm;
	int8_t type;
	int signal_good;
} wifi_adapter_rx_status_t_uplink;

typedef struct {
        time_t last_update;
        uint32_t received_block_cnt;
        uint32_t damaged_block_cnt;
	uint32_t lost_packet_cnt;
	uint32_t received_packet_cnt;
	uint32_t lost_per_block_cnt;
        uint32_t tx_restart_cnt;
	uint32_t kbitrate;
        uint32_t wifi_adapter_cnt;
        wifi_adapter_rx_status_t adapter[8];
} wifibroadcast_rx_status_t;

typedef struct {
        time_t last_update;
        uint32_t received_block_cnt;
        uint32_t damaged_block_cnt;
	uint32_t lost_packet_cnt;
	uint32_t received_packet_cnt;
	uint32_t lost_per_block_cnt;
        uint32_t tx_restart_cnt;
	uint32_t kbitrate;
        uint32_t wifi_adapter_cnt;
        wifi_adapter_rx_status_t adapter[8];
} wifibroadcast_rx_status_t_osd;

typedef struct {
    time_t last_update;
    uint32_t received_block_cnt;
    uint32_t damaged_block_cnt;
	uint32_t lost_packet_cnt;
	uint32_t received_packet_cnt;
	uint32_t lost_per_block_cnt;
    uint32_t tx_restart_cnt;
	uint32_t kbitrate;
    uint32_t wifi_adapter_cnt;
    wifi_adapter_rx_status_t adapter[8];
} wifibroadcast_rx_status_t_rc;

typedef struct {
    time_t last_update;
    uint32_t received_block_cnt;
    uint32_t damaged_block_cnt;
	uint32_t lost_packet_cnt;
	uint32_t received_packet_cnt;
	uint32_t lost_per_block_cnt;
    uint32_t tx_restart_cnt;
	uint32_t kbitrate;
    uint32_t wifi_adapter_cnt;
    wifi_adapter_rx_status_t adapter[8];
} wifibroadcast_rx_status_t_uplink;

typedef struct {
    time_t last_update;
    uint8_t cpuload;
    uint8_t temp;
    uint32_t injected_block_cnt;
    uint32_t skipped_fec_cnt;
    uint32_t injection_fail_cnt;
    long long injection_time_block;
    uint16_t bitrate_kbit;
    uint16_t bitrate_measured_kbit;
    uint8_t cts;
    uint8_t undervolt;
} wifibroadcast_rx_status_t_sysair;

//GroundPi system status
typedef struct{
	uint8_t cpuload;
    uint8_t temp;
	uint8_t undervolt;
} status_t_sys_gnd;

typedef struct {
    uint32_t received_packet_cnt;
    int8_t current_signal_dbm;
    int8_t type; // 0 = Atheros, 1 = Ralink
    int8_t signal_good;
} __attribute__((packed)) wifi_adapter_rx_status_forward_t;

typedef struct {
    uint32_t damaged_block_cnt; // number bad blocks video downstream
    uint32_t lost_packet_cnt; // lost packets video downstream
    uint32_t skipped_packet_cnt; // skipped packets video downstream
    uint32_t injection_fail_cnt;  // Video injection failed downstream
    uint32_t received_packet_cnt; // packets received video downstream
    uint32_t kbitrate; // live video kilobitrate per second video downstream
    uint32_t kbitrate_measured; // max measured kbitrate during tx startup
    uint32_t kbitrate_set; // set kilobitrate (measured * bitrate_percent) during tx startup
    uint32_t lost_packet_cnt_telemetry_up; // lost packets telemetry uplink
    uint32_t lost_packet_cnt_telemetry_down; // lost packets telemetry downlink
    uint32_t lost_packet_cnt_msp_up; // lost packets msp uplink (not used at the moment)
    uint32_t lost_packet_cnt_msp_down; // lost packets msp downlink (not used at the moment)
    uint32_t lost_packet_cnt_rc; // lost packets rc link
    int8_t current_signal_joystick_uplink; // signal strength in dbm at air pi (telemetry upstream and rc link)
    int8_t current_signal_telemetry_uplink;
    int8_t joystick_connected; // 0 = no joystick connected, 1 = joystick connected
    float HomeLat;
    float HomeLon;
    uint8_t cpuload_gnd; // CPU load Ground Pi
    uint8_t temp_gnd; // CPU temperature Ground Pi
    uint8_t cpuload_air; // CPU load Air Pi
    uint8_t temp_air; // CPU temperature Air Pi
    uint32_t wifi_adapter_cnt; // number of wifi adapters
    wifi_adapter_rx_status_forward_t adapter[6]; // same struct as in wifibroadcast lib.h
} __attribute__((packed)) wifibroadcast_rx_status_forward_t;

typedef struct 
{
	long long ts; //recieve timestemp
	uint8_t severity;
	char *message;
} uav_message_t;

typedef struct
{
	float current_range;
	float max_range;
} rangefinder_t;

typedef struct
{
	float current_height;
	float loaded;
	uint16_t spacing;
	float terrain_height;
} terrain_data_t;


typedef struct {
	uint32_t validmsgsrx;
	uint32_t datarx;

	float voltage;
	float ampere;
	int32_t mah;
	float msl_altitude;
	float rel_altitude;
	double longitude;
	double latitude;
	float heading;
	float cog; //course over ground
	float speed;
	float airspeed;
	uint16_t throttle;
	float roll, pitch;
	uint8_t sats;
	uint8_t fix;
	uint16_t hdop;
	uint8_t armed;
	uint8_t rssi;

	uint8_t home_fix;
	float mav_climb;
	double vx;
	double vy;
	double vz;
	float home_lat;
	float home_lon;

	uav_message_t msg;
	rangefinder_t rangefinder;
	
//#if defined(FRSKY)
	int16_t x, y, z; // also needed for smartport
	int16_t ew, ns;
//#endif

#if defined(SMARTPORT)
	uint8_t swr;
	float rx_batt;
	float adc1;
	float adc2;
	float vario;
#endif

#if defined(MAVLINK)
	uint32_t mav_flightmode;
//	float mav_climb;
	uint32_t version;
	uint16_t vendor;
	uint16_t product;
//	double vx;
//	double vy;
//	double vz;
//	uint16_t hdop;
	uint16_t servo1;
	uint16_t mission_current_seq;
	uint16_t wp_dist;
	uint32_t SP;
	uint32_t SE;
	uint32_t SH;
	int32_t total_amps;
	terrain_data_t terrain_data;
#endif

#if defined(LTM)
// ltm S frame
	uint8_t ltm_status;
	uint8_t ltm_failsafe;
	uint8_t ltm_flightmode;
// ltm N frame
	uint8_t ltm_gpsmode;
	uint8_t ltm_navmode;
	uint8_t ltm_navaction;
	uint8_t ltm_wpnumber;
	uint8_t ltm_naverror;
// ltm X frame
//	uint16_t ltm_hdop;
	uint8_t ltm_hw_status;
	uint8_t ltm_x_counter;
	uint8_t ltm_disarm_reason;
// ltm O frame
	float ltm_home_altitude;
	double ltm_home_longitude;
	double ltm_home_latitude;
	uint8_t ltm_osdon;
	uint8_t ltm_homefix;
#endif

#if defined(VOT)
        uint8_t flightmode;
        float vtxvoltage;
        float camvoltage;
        float rxvoltage;
        float vario;
        int16_t rpm;
        int16_t temp;
        uint16_t mahconsumed;
        uint16_t compassdegrees;
        uint8_t lq;
        float distance;
        uint16_t coursedegrees;
//        float hdop;
#endif

#ifdef RELAY
	wifibroadcast_rx_status_forward_t *rx_status;
#else
	wifibroadcast_rx_status_t *rx_status;
#endif
	wifibroadcast_rx_status_t_osd *rx_status_osd;
	wifibroadcast_rx_status_t_rc *rx_status_rc;
	wifibroadcast_rx_status_t_uplink *rx_status_uplink;
	wifibroadcast_rx_status_t_sysair *rx_status_sysair;
	status_t_sys_gnd status_sys_gnd;
} telemetry_data_t;

#ifndef RELAY
wifibroadcast_rx_status_t *telemetry_wbc_status_memory_open(void);
#endif
wifibroadcast_rx_status_t_osd *telemetry_wbc_status_memory_open_osd(void);
wifibroadcast_rx_status_t_rc *telemetry_wbc_status_memory_open_rc(void);
wifibroadcast_rx_status_t_uplink *telemetry_wbc_status_memory_open_uplink(void);
wifibroadcast_rx_status_t_sysair *telemetry_wbc_status_memory_open_sysair(void);
