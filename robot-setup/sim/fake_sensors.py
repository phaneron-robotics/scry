#!/usr/bin/env python3
"""
Synthetic sensor publishers for the scry-sim stack.

Drives the new Sensors viz section in the Android app. We synthesize seven
`sensor_msgs/*` streams — none of which the TurtleBot3 Gazebo plugin
publishes out of the box — with deliberately interesting dynamics so the
panels actually move on screen:

  /imu_fake          (sensor_msgs/Imu)            — slow spin + sin-wave accel
  /battery           (sensor_msgs/BatteryState)   — slow discharge + cell drift
  /range             (sensor_msgs/Range)          — wandering 0.5..3 m sonar hit
  /temperature       (sensor_msgs/Temperature)    — diurnal swing 22..26 °C
  /humidity          (sensor_msgs/RelativeHumidity) — slow drift 0.40..0.60
  /pressure          (sensor_msgs/FluidPressure)  — 101325 Pa ± weather noise
  /illuminance       (sensor_msgs/Illuminance)    — log-spaced lux changes

The TurtleBot3 sim already publishes `/imu` from the IMU plugin. We
deliberately use `/imu_fake` here so the two coexist — the user can pick
whichever in the picker.

All streams use a single timer. Default rate is 10 Hz which exercises
panel rendering without hammering the bus.
"""

from __future__ import annotations

import argparse
import math
import random
import time

import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, QoSReliabilityPolicy, QoSDurabilityPolicy

from std_msgs.msg import Header
from sensor_msgs.msg import (
    BatteryState,
    FluidPressure,
    Illuminance,
    Imu,
    Joy,
    MagneticField,
    Range,
    RelativeHumidity,
    Temperature,
)
from geometry_msgs.msg import Wrench, WrenchStamped


def make_header(node: Node, frame_id: str) -> Header:
    h = Header()
    h.stamp = node.get_clock().now().to_msg()
    h.frame_id = frame_id
    return h


class FakeSensorsNode(Node):
    """One node, seven publishers, one shared timer."""

    def __init__(self, args: argparse.Namespace) -> None:
        super().__init__("scry_sim_fake_sensors")

        # Reliable + KEEP_LAST(10) is what nearly every real sensor driver
        # uses for these low-rate, single-value topics.
        self.qos = QoSProfile(
            depth=10,
            reliability=QoSReliabilityPolicy.RELIABLE,
            durability=QoSDurabilityPolicy.VOLATILE,
        )

        # ── publishers ──
        self.pub_imu = self.create_publisher(Imu, args.imu_topic, self.qos)
        self.pub_bat = self.create_publisher(BatteryState, args.battery_topic, self.qos)
        self.pub_rng = self.create_publisher(Range, args.range_topic, self.qos)
        self.pub_tmp = self.create_publisher(Temperature, args.temperature_topic, self.qos)
        self.pub_hum = self.create_publisher(RelativeHumidity, args.humidity_topic, self.qos)
        self.pub_prs = self.create_publisher(FluidPressure, args.pressure_topic, self.qos)
        self.pub_lux = self.create_publisher(Illuminance, args.illuminance_topic, self.qos)
        self.pub_mag = self.create_publisher(MagneticField, args.magnetic_topic, self.qos)
        self.pub_wrn = self.create_publisher(WrenchStamped, args.wrench_topic, self.qos)
        self.pub_joy = self.create_publisher(Joy, args.joy_topic, self.qos)

        # ── frame_ids ──
        self.imu_frame = args.imu_frame
        self.range_frame = args.range_frame
        self.scalar_frame = args.scalar_frame

        # ── timing ──
        self.t0 = time.monotonic()
        period = 1.0 / max(args.rate, 0.5)
        self.create_timer(period, self._tick)

        # ── battery state — discharges over `args.battery_minutes` ──
        self.battery_minutes = max(args.battery_minutes, 0.5)
        self.battery_full_v = args.battery_full_v
        self.battery_empty_v = args.battery_empty_v
        self.battery_cells = max(args.battery_cells, 1)

        # ── range bounds for the synthetic sonar ──
        self.range_min = args.range_min
        self.range_max = args.range_max
        self.range_fov = args.range_fov

        self.get_logger().info(
            "fake_sensors @ %.1f Hz publishing on: %s, %s, %s, %s, %s, %s, %s"
            % (
                args.rate,
                args.imu_topic, args.battery_topic, args.range_topic,
                args.temperature_topic, args.humidity_topic,
                args.pressure_topic, args.illuminance_topic,
            )
        )

    # ── tick ──────────────────────────────────────────────────────────

    def _tick(self) -> None:
        t = time.monotonic() - self.t0
        self._pub_imu(t)
        self._pub_battery(t)
        self._pub_range(t)
        self._pub_temperature(t)
        self._pub_humidity(t)
        self._pub_pressure(t)
        self._pub_illuminance(t)
        self._pub_magnetic(t)
        self._pub_wrench(t)
        self._pub_joy(t)

    # ── per-sensor synthesis ──────────────────────────────────────────

    def _pub_imu(self, t: float) -> None:
        # Slow yaw rotation around Z + small pitch oscillation. Quaternion
        # built from yaw=t/8 rad, pitch=0.1*sin(t).
        yaw = t / 8.0
        pitch = 0.1 * math.sin(t)
        roll = 0.0
        cy = math.cos(yaw * 0.5); sy = math.sin(yaw * 0.5)
        cp = math.cos(pitch * 0.5); sp = math.sin(pitch * 0.5)
        cr = math.cos(roll * 0.5); sr = math.sin(roll * 0.5)
        qw = cr * cp * cy + sr * sp * sy
        qx = sr * cp * cy - cr * sp * sy
        qy = cr * sp * cy + sr * cp * sy
        qz = cr * cp * sy - sr * sp * cy

        msg = Imu()
        msg.header = make_header(self, self.imu_frame)
        msg.orientation.x = qx
        msg.orientation.y = qy
        msg.orientation.z = qz
        msg.orientation.w = qw
        msg.angular_velocity.x = random.gauss(0.0, 0.01)
        msg.angular_velocity.y = 0.1 * math.cos(t)
        msg.angular_velocity.z = 0.125  # matches the yaw rate above
        # Linear accel includes 1 g down in body Z (sensor at rest, level).
        # Add a tiny lateral wobble so the panel's "off-gravity" callout moves.
        msg.linear_acceleration.x = 0.05 * math.sin(t * 1.3)
        msg.linear_acceleration.y = 0.05 * math.cos(t * 0.7)
        msg.linear_acceleration.z = 9.80665 + 0.02 * math.sin(t * 2.1)
        # Mark covariances as known-but-small (first element != -1).
        msg.orientation_covariance = [
            1e-4, 0.0, 0.0,
            0.0, 1e-4, 0.0,
            0.0, 0.0, 1e-4,
        ]
        msg.angular_velocity_covariance = [
            1e-3, 0.0, 0.0,
            0.0, 1e-3, 0.0,
            0.0, 0.0, 1e-3,
        ]
        msg.linear_acceleration_covariance = [
            1e-2, 0.0, 0.0,
            0.0, 1e-2, 0.0,
            0.0, 0.0, 1e-2,
        ]
        self.pub_imu.publish(msg)

    def _pub_battery(self, t: float) -> None:
        # Linear discharge over `battery_minutes`, looping back to 100 % so
        # the panel never sits empty during long demos.
        cycle_s = self.battery_minutes * 60.0
        frac = max(0.0, min(1.0, 1.0 - (t % cycle_s) / cycle_s))
        v = self.battery_empty_v + frac * (self.battery_full_v - self.battery_empty_v)
        # Tiny per-cell drift so the imbalance bar doesn't read perfect-zero.
        cells = [
            v / self.battery_cells + random.gauss(0.0, 0.005)
            for _ in range(self.battery_cells)
        ]
        cell_temps = [25.0 + random.gauss(0.0, 0.3) for _ in range(self.battery_cells)]

        msg = BatteryState()
        msg.header = make_header(self, self.scalar_frame)
        msg.voltage = float(v)
        msg.current = -1.5 - 0.2 * math.sin(t / 7.0)  # discharging convention is negative
        msg.charge = float(frac * 5.0)        # Ah remaining (designed for 5 Ah pack)
        msg.capacity = 5.0
        msg.design_capacity = 5.0
        msg.percentage = float(frac)          # 0..1, NOT 0..100
        msg.power_supply_status = BatteryState.POWER_SUPPLY_STATUS_DISCHARGING
        msg.power_supply_health = BatteryState.POWER_SUPPLY_HEALTH_GOOD
        msg.power_supply_technology = BatteryState.POWER_SUPPLY_TECHNOLOGY_LIPO
        msg.present = True
        msg.cell_voltage = cells
        msg.cell_temperature = cell_temps
        msg.location = "main"
        msg.serial_number = "SCRY-SIM-001"
        self.pub_bat.publish(msg)

    def _pub_range(self, t: float) -> None:
        # Smooth wander 0.5..3 m, plus a short out-of-range "spike" every
        # ~30 s so the red-clamp behavior in the panel is visible.
        baseline = 1.75 + 1.25 * math.sin(t / 5.0)
        if (int(t) % 30) == 0 and (t - int(t)) < 0.2:
            baseline = self.range_max + 0.5  # out-of-range pulse
        msg = Range()
        msg.header = make_header(self, self.range_frame)
        msg.radiation_type = Range.ULTRASOUND
        msg.field_of_view = self.range_fov
        msg.min_range = self.range_min
        msg.max_range = self.range_max
        msg.range = float(baseline)
        self.pub_rng.publish(msg)

    def _pub_temperature(self, t: float) -> None:
        # 24 °C ± 2 °C "diurnal" swing (compressed to a 60 s cycle for demo).
        c = 24.0 + 2.0 * math.sin(t / 60.0 * 2 * math.pi)
        msg = Temperature()
        msg.header = make_header(self, self.scalar_frame)
        msg.temperature = float(c)
        msg.variance = 0.05
        self.pub_tmp.publish(msg)

    def _pub_humidity(self, t: float) -> None:
        # 0..1, drift slowly between 0.40 and 0.60.
        h = 0.50 + 0.10 * math.sin(t / 90.0)
        msg = RelativeHumidity()
        msg.header = make_header(self, self.scalar_frame)
        msg.relative_humidity = float(h)
        msg.variance = 1e-4
        self.pub_hum.publish(msg)

    def _pub_pressure(self, t: float) -> None:
        # 101 325 Pa ± "weather" noise, slow.
        p = 101_325.0 + 200.0 * math.sin(t / 120.0) + random.gauss(0.0, 5.0)
        msg = FluidPressure()
        msg.header = make_header(self, self.scalar_frame)
        msg.fluid_pressure = float(p)
        msg.variance = 25.0
        self.pub_prs.publish(msg)

    def _pub_illuminance(self, t: float) -> None:
        # Log-spaced sweep across "indoor low" → "daylight" so the dial's
        # log scale gets exercised: 50 → 50 000 lux over 60 s.
        phase = (t % 60.0) / 60.0  # 0..1
        # Triangle wave between 0 and 1 then exponentiate.
        tri = 1.0 - abs(2.0 * phase - 1.0)
        lux = 50.0 * (10.0 ** (3.0 * tri))  # 50 .. 50 000
        msg = Illuminance()
        msg.header = make_header(self, self.scalar_frame)
        msg.illuminance = float(lux)
        msg.variance = 1.0
        self.pub_lux.publish(msg)

    def _pub_magnetic(self, t: float) -> None:
        # Earth-field magnitude ≈ 50 µT at mid-latitudes. We rotate a vector
        # in the XY plane synchronized with the IMU yaw so the
        # "calibration trail" panel draws a nice circle as time advances.
        # Z component fixed (dip ≈ 60° at temperate latitudes, mz negative
        # in NED-on-body frame).
        yaw = t / 8.0
        bxy_t = 25e-6  # 25 µT horizontal component
        bz_t = -45e-6  # ≈ 60° dip
        mx = bxy_t * math.cos(yaw) + random.gauss(0.0, 0.5e-6)
        my = bxy_t * math.sin(yaw) + random.gauss(0.0, 0.5e-6)
        mz = bz_t + random.gauss(0.0, 0.3e-6)
        msg = MagneticField()
        msg.header = make_header(self, self.imu_frame)
        msg.magnetic_field.x = float(mx)
        msg.magnetic_field.y = float(my)
        msg.magnetic_field.z = float(mz)
        msg.magnetic_field_covariance = [
            1e-12, 0.0, 0.0,
            0.0, 1e-12, 0.0,
            0.0, 0.0, 1e-12,
        ]
        self.pub_mag.publish(msg)

    def _pub_wrench(self, t: float) -> None:
        # Pretend an end-effector force/torque sensor — a slow push down
        # with sinusoidal yz wobble + a small twist about Z.
        msg = WrenchStamped()
        msg.header = make_header(self, "ft_sensor")
        msg.wrench.force.x = 2.0 * math.sin(t / 4.0)
        msg.wrench.force.y = 1.0 * math.cos(t / 5.0)
        msg.wrench.force.z = -8.0 + 1.5 * math.sin(t / 3.0)
        msg.wrench.torque.x = 0.05 * math.sin(t / 6.0)
        msg.wrench.torque.y = 0.10 * math.cos(t / 7.0)
        msg.wrench.torque.z = 0.40 * math.sin(t / 9.0)
        self.pub_wrn.publish(msg)

    def _pub_joy(self, t: float) -> None:
        # Mimic a real /joy stream: 8 axes, 11 buttons (Xbox layout sizes).
        # The left stick wobbles, the right stick stays centred, triggers
        # rest at -1.0 (Linux joy idle), D-pad axes are 0.0. Buttons
        # rotate one-on at a time so the panel pip animates.
        axes = [
            0.6 * math.sin(t / 2.0),         # 0 - left X
            0.6 * math.cos(t / 2.0),         # 1 - left Y
            0.0,                              # 2 - right X
            0.0,                              # 3 - right Y
            -1.0 + 0.5 * (1.0 + math.sin(t)),  # 4 - LT (-1..0)
            -1.0,                             # 5 - RT
            0.0, 0.0,                         # 6, 7 - D-pad X/Y
        ]
        buttons = [0] * 11
        # One button "held" at any moment, walking around 0..10.
        held_idx = int(t) % 11
        buttons[held_idx] = 1
        msg = Joy()
        msg.header = make_header(self, "joy")
        msg.axes = [float(a) for a in axes]
        msg.buttons = list(buttons)
        self.pub_joy.publish(msg)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--rate", type=float, default=10.0, help="Hz")
    # Per-topic overrides. Defaults match what we recommend the Sensors
    # picker discover.
    p.add_argument("--imu-topic", default="/imu_fake")
    p.add_argument("--battery-topic", default="/battery")
    p.add_argument("--range-topic", default="/range")
    p.add_argument("--temperature-topic", default="/temperature")
    p.add_argument("--humidity-topic", default="/humidity")
    p.add_argument("--pressure-topic", default="/pressure")
    p.add_argument("--illuminance-topic", default="/illuminance")
    p.add_argument("--magnetic-topic", default="/magnetic_field")
    p.add_argument("--wrench-topic", default="/wrench")
    p.add_argument("--joy-topic", default="/joy")
    p.add_argument("--imu-frame", default="imu_link")
    p.add_argument("--range-frame", default="range_link")
    p.add_argument("--scalar-frame", default="base_link")
    # Battery cycle params.
    p.add_argument("--battery-minutes", type=float, default=10.0,
        help="Minutes for one full discharge cycle (loops).")
    p.add_argument("--battery-full-v", type=float, default=12.6)
    p.add_argument("--battery-empty-v", type=float, default=10.5)
    p.add_argument("--battery-cells", type=int, default=3)
    # Range params.
    p.add_argument("--range-min", type=float, default=0.10)
    p.add_argument("--range-max", type=float, default=4.00)
    p.add_argument("--range-fov", type=float, default=0.524)  # ≈ 30°
    return p.parse_args()


def main() -> None:
    args = parse_args()
    rclpy.init()
    node = FakeSensorsNode(args)
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == "__main__":
    main()
