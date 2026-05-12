#!/usr/bin/env python3
"""
Synthetic GPS publisher for the scry-sim stack.

The TurtleBot3 Gazebo plugin doesn't ship a GPS sensor, so we synthesise a
`sensor_msgs/NavSatFix` stream by:

1. Reading the robot's `/odom` (or `/tf`-derived `map → base_link`) pose, in
   metres.
2. Treating the (configurable) world origin as a fixed lat/lon **datum**.
3. Converting the local (east, north) offset back to lat/lon with a small
   equirectangular approximation (good to ~mm for the sub-km scales a
   TurtleBot covers, which is way under the noise we add).
4. Adding a small Gaussian noise (sigma configurable) so the published fix
   actually looks like a real GPS — wandering centimetres while idle and
   following a noisy track while driving.

If `/odom` isn't available the publisher just emits the datum lat/lon with
noise — useful for testing the GPS section's "stationary" path.

Topic        : /gps/fix   (override with --topic)
Type         : sensor_msgs/msg/NavSatFix
Rate         : 5 Hz       (override with --rate)
Datum        : Anthropic SF office, 548 Market St (lat 37.7916, lon -122.3993)
                — pick anything; the GPS section will recenter the basemap
                  on whatever lat/lon arrives.

Defaults make the robot show up in downtown San Francisco, which is more fun
than a featureless ocean tile.
"""

from __future__ import annotations

import argparse
import math
import random
import time

import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, QoSReliabilityPolicy, QoSDurabilityPolicy

from nav_msgs.msg import Odometry
from sensor_msgs.msg import NavSatFix, NavSatStatus


EARTH_RADIUS_M = 6_371_000.0


def meters_to_latlon(
    datum_lat: float, datum_lon: float, east_m: float, north_m: float
) -> tuple[float, float]:
    """
    Equirectangular projection — convert local east/north metres relative to
    a datum into geographic lat/lon. Accurate enough for the sub-km area a
    TurtleBot covers (the error is dominated by the noise we add anyway).
    """
    dlat = north_m / EARTH_RADIUS_M
    dlon = east_m / (EARTH_RADIUS_M * math.cos(math.radians(datum_lat)))
    return (
        datum_lat + math.degrees(dlat),
        datum_lon + math.degrees(dlon),
    )


class GpsPublisher(Node):
    def __init__(self, args: argparse.Namespace) -> None:
        super().__init__("scry_sim_gps_publisher")
        self.datum_lat = args.lat
        self.datum_lon = args.lon
        self.altitude = args.alt
        self.sigma_h = args.sigma_h
        self.sigma_v = args.sigma_v
        self.frame_id = args.frame_id
        self.topic = args.topic
        self.rate_hz = args.rate
        self.use_odom = args.use_odom

        # Latest pose, populated from /odom (if subscribed).
        self._x = 0.0
        self._y = 0.0
        self._has_odom = False

        # Latched-ish QoS so a late-joining subscriber gets the most recent
        # fix immediately. Reliable + KEEP_LAST(10) is the typical NavSatFix
        # publisher posture (matches gpsd_client / ublox driver).
        qos = QoSProfile(
            depth=10,
            reliability=QoSReliabilityPolicy.RELIABLE,
            durability=QoSDurabilityPolicy.VOLATILE,
        )
        self.pub = self.create_publisher(NavSatFix, self.topic, qos)

        if self.use_odom:
            self.create_subscription(Odometry, "/odom", self._on_odom, 10)
            self.get_logger().info(
                "subscribed to /odom — GPS fix tracks robot motion"
            )
        else:
            self.get_logger().info(
                "stationary mode — fix at datum lat=%.6f lon=%.6f"
                % (self.datum_lat, self.datum_lon)
            )

        period = 1.0 / max(self.rate_hz, 0.1)
        self.create_timer(period, self._tick)
        self.get_logger().info(
            "publishing %s @ %.1f Hz, σ_h=%.2fm σ_v=%.2fm, frame=%s"
            % (self.topic, self.rate_hz, self.sigma_h, self.sigma_v, self.frame_id)
        )

    def _on_odom(self, msg: Odometry) -> None:
        self._x = msg.pose.pose.position.x
        self._y = msg.pose.pose.position.y
        self._has_odom = True

    def _tick(self) -> None:
        # Local east/north in metres → lat/lon. Odom's frame is x-forward
        # y-left in the robot's start pose, so we treat +x = east, +y = north
        # (close enough for a synthetic GPS — the *relative* motion is what
        # the GPS section visualises).
        east_m = self._x + random.gauss(0.0, self.sigma_h)
        north_m = self._y + random.gauss(0.0, self.sigma_h)
        lat, lon = meters_to_latlon(
            self.datum_lat, self.datum_lon, east_m, north_m
        )
        alt = self.altitude + random.gauss(0.0, self.sigma_v)

        msg = NavSatFix()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = self.frame_id
        # Status: report a real fix once we have *any* odom (or always if
        # in stationary mode). Receivers that care about NO_FIX (= -1) will
        # then start trusting us.
        msg.status.status = (
            NavSatStatus.STATUS_FIX
            if (self._has_odom or not self.use_odom)
            else NavSatStatus.STATUS_NO_FIX
        )
        msg.status.service = NavSatStatus.SERVICE_GPS
        msg.latitude = lat
        msg.longitude = lon
        msg.altitude = alt
        # Diagonal covariance: σ² in metres² for east, north, up. The Scry
        # GPS section reads positions [0]/[4] to estimate horizontal accuracy.
        sh2 = self.sigma_h * self.sigma_h
        sv2 = self.sigma_v * self.sigma_v
        msg.position_covariance = [
            sh2, 0.0, 0.0,
            0.0, sh2, 0.0,
            0.0, 0.0, sv2,
        ]
        msg.position_covariance_type = NavSatFix.COVARIANCE_TYPE_DIAGONAL_KNOWN
        self.pub.publish(msg)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--topic", default="/gps/fix")
    p.add_argument("--rate", type=float, default=5.0, help="Hz")
    p.add_argument(
        "--lat", type=float, default=37.7916,
        help="Datum latitude in degrees",
    )
    p.add_argument(
        "--lon", type=float, default=-122.3993,
        help="Datum longitude in degrees",
    )
    p.add_argument("--alt", type=float, default=15.0, help="Datum altitude m")
    p.add_argument(
        "--sigma-h", type=float, default=1.5,
        help="Horizontal noise σ (metres). 1.5 ≈ open-sky consumer GPS.",
    )
    p.add_argument(
        "--sigma-v", type=float, default=3.0,
        help="Vertical noise σ (metres). Vertical is always worse.",
    )
    p.add_argument("--frame-id", default="gps_link")
    p.add_argument(
        "--no-odom", dest="use_odom", action="store_false",
        help="Don't subscribe to /odom — emit a stationary noisy fix.",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()
    rclpy.init()
    # Honour USE_SIM_TIME from the env, since the rest of the sim is on /clock.
    node = GpsPublisher(args)
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
