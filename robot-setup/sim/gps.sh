#!/usr/bin/env bash
# Run the synthetic GPS publisher. Reads /odom from the TurtleBot3 sim and
# emits sensor_msgs/NavSatFix on /gps/fix at 5 Hz.
#
# Env vars (all optional):
#   GPS_TOPIC      output topic       (default /gps/fix)
#   GPS_RATE       Hz                 (default 5)
#   GPS_LAT        datum latitude °   (default 37.7916  — SF)
#   GPS_LON        datum longitude °  (default -122.3993)
#   GPS_ALT        datum altitude m   (default 15)
#   GPS_SIGMA_H    horizontal noise m (default 1.5)
#   GPS_SIGMA_V    vertical noise m   (default 3.0)
#   GPS_NO_ODOM    set to "1" to publish a stationary fix
set -eo pipefail
set +u
source /opt/ros/jazzy/setup.bash
set -u

ARGS=(
    --topic "${GPS_TOPIC:-/gps/fix}"
    --rate "${GPS_RATE:-5}"
    --lat "${GPS_LAT:-37.7916}"
    --lon "${GPS_LON:--122.3993}"
    --alt "${GPS_ALT:-15.0}"
    --sigma-h "${GPS_SIGMA_H:-1.5}"
    --sigma-v "${GPS_SIGMA_V:-3.0}"
)
[ "${GPS_NO_ODOM:-0}" = "1" ] && ARGS+=(--no-odom)

echo "[scry-sim-gps] publishing ${GPS_TOPIC:-/gps/fix} @ ${GPS_RATE:-5} Hz"
exec python3 /opt/scry-sim/gps_publisher.py "${ARGS[@]}"
