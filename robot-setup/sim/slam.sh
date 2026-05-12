#!/usr/bin/env bash
# Run SLAM Toolbox against the running TurtleBot3 sim.
#
# Drive the robot (teleop.sh in another shell) while this runs to build a
# map. The map is published on /map and visible in RViz.
#
# Save the resulting map with:
#   ros2 run nav2_map_server map_saver_cli -f /opt/scry-sim/maps/my_map
set -eo pipefail

set +u
source /opt/ros/jazzy/setup.bash
[ -f /opt/turtlebot3_ws/install/setup.bash ] && source /opt/turtlebot3_ws/install/setup.bash
set -u

export TURTLEBOT3_MODEL="${TURTLEBOT3_MODEL:-burger}"

mkdir -p /opt/scry-sim/maps

# slam_toolbox's online_async slam works well with simulated lidar.
# Honour USE_SIM_TIME from compose so toggling it is a single env change.
exec ros2 launch slam_toolbox online_async_launch.py \
    use_sim_time:="${USE_SIM_TIME:-true}"
