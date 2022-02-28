#include "osdconfig.h"

#ifdef MAVLINK
    #include "telemetry.h"
    #include "mavlink/common/mavlink.h"

    int mavlink_read(telemetry_data_t *td, uint8_t *buf, int buflen);


    #define FLTMODE_PLANE_MANUAL    0
    #define FLTMODE_PLANE_CIRCLE    1
    #define FLTMODE_PLANE_STABILIZ  2
    #define FLTMODE_PLANE_TRAINING  3
    #define FLTMODE_PLANE_ACRO      4
    #define FLTMODE_PLANE_FBWA      5
    #define FLTMODE_PLANE_FBWB      6
    #define FLTMODE_PLANE_CRUISE    7
    #define FLTMODE_PLANE_AUTOTUNE  8
    #define FLTMODE_PLANE_AUTO      10
    #define FLTMODE_PLANE_RTL       11
    #define FLTMODE_PLANE_LOITER    12
    #define FLTMODE_PLANE_TAKEOFF   13
    #define FLTMODE_PLANE_AVOID_ADSB 14
    #define FLTMODE_PLANE_GUIDED    15
    #define FLTMODE_PLANE_QSTABILIZE 17
    #define FLTMODE_PLANE_QHOVER    18
    #define FLTMODE_PLANE_QLOITER   19
    #define FLTMODE_PLANE_QLAND     20
    #define FLTMODE_PLANE_QRTL      21
    #define FLTMODE_PLANE_QAUTOTUNE 22
    #define FLTMODE_PLANE_QACRO     23
    #define FLTMODE_PLANE_THERMAL   24
    #define FLTMODE_PLANE_LOITER_TO_QLAND 25

    #define FLTMODE_COPTER_STABILIZE    0
    #define FLTMODE_COPTER_ACRO         1
    #define FLTMODE_COPTER_ALTHOLD      2
    #define FLTMODE_COPTER_AUTO         3
    #define FLTMODE_COPTER_GUIDED       4
    #define FLTMODE_COPTER_LOITER       5
    #define FLTMODE_COPTER_RTL          6
    #define FLTMODE_COPTER_CIRCLE       7
    #define FLTMODE_COPTER_LAND         9
    #define FLTMODE_COPTER_DRIFT        11
    #define FLTMODE_COPTER_SPORT        13
    #define FLTMODE_COPTER_FLIP         14
    #define FLTMODE_COPTER_AUTOTUNE     15
    #define FLTMODE_COPTER_POSHOLD      16
    #define FLTMODE_COPTER_BRAKE        17
    #define FLTMODE_COPTER_THROW        18
    #define FLTMODE_COPTER_AVOID_ADSB   19
    #define FLTMODE_COPTER_GUIDED_NO_GPS 20
    #define FLTMODE_COPTER_SMART_RTL    21
    #define FLTMODE_COPTER_FLOW_HOLD    22
    #define FLTMODE_COPTER_FOLLOW       23
    #define FLTMODE_COPTER_ZIGZAG       24
    #define FLTMODE_COPTER_SYSTEM_ID    25
    #define FLTMODE_COPTER_HELI_AUTOROTATE 26
    #define FLTMODE_COPTER_AUTO_RTL     27
#endif
