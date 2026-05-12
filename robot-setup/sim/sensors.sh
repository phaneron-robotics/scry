#!/usr/bin/env bash
# Run the synthetic sensor publisher. Emits seven sensor_msgs/* streams
# at 10 Hz so the Sensors viz section in the Android app has something
# to show on every panel kind.
#
# Env vars (all optional):
#   SENSORS_RATE              publish rate Hz                 (default 10)
#   SENSORS_IMU_TOPIC         IMU output topic                (default /imu_fake)
#   SENSORS_BATTERY_TOPIC     BatteryState output topic       (default /battery)
#   SENSORS_RANGE_TOPIC       Range output topic              (default /range)
#   SENSORS_TEMP_TOPIC        Temperature output topic        (default /temperature)
#   SENSORS_HUMIDITY_TOPIC    RelativeHumidity output topic   (default /humidity)
#   SENSORS_PRESSURE_TOPIC    FluidPressure output topic      (default /pressure)
#   SENSORS_ILLUM_TOPIC       Illuminance output topic        (default /illuminance)
#   SENSORS_MAG_TOPIC         MagneticField output topic      (default /magnetic_field)
#   SENSORS_WRENCH_TOPIC      WrenchStamped output topic      (default /wrench)
#   SENSORS_JOY_TOPIC         Joy output topic                (default /joy)
#   SENSORS_BATTERY_MINUTES   minutes for one discharge cycle (default 10)
set -eo pipefail
set +u
source /opt/ros/jazzy/setup.bash
set -u

ARGS=(
    --rate "${SENSORS_RATE:-10}"
    --imu-topic "${SENSORS_IMU_TOPIC:-/imu_fake}"
    --battery-topic "${SENSORS_BATTERY_TOPIC:-/battery}"
    --range-topic "${SENSORS_RANGE_TOPIC:-/range}"
    --temperature-topic "${SENSORS_TEMP_TOPIC:-/temperature}"
    --humidity-topic "${SENSORS_HUMIDITY_TOPIC:-/humidity}"
    --pressure-topic "${SENSORS_PRESSURE_TOPIC:-/pressure}"
    --illuminance-topic "${SENSORS_ILLUM_TOPIC:-/illuminance}"
    --magnetic-topic "${SENSORS_MAG_TOPIC:-/magnetic_field}"
    --wrench-topic "${SENSORS_WRENCH_TOPIC:-/wrench}"
    --joy-topic "${SENSORS_JOY_TOPIC:-/joy}"
    --battery-minutes "${SENSORS_BATTERY_MINUTES:-10}"
)

echo "[scry-sim-sensors] publishing 10 synthetic sensor streams @ ${SENSORS_RATE:-10} Hz"
exec python3 /opt/scry-sim/fake_sensors.py "${ARGS[@]}"
