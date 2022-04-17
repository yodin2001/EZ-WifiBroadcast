#pragma once
#include "telemetry.h"

// function for loging telemetry data and video transmision parameters to file
// current_time - time in [ms]
// times_per_sec - how offen telemetry is loging (min 1 times per sec, max 5 times per sec)
void telemetry_loging(telemetry_data_t *td,long long current_time,int times_per_sec);
