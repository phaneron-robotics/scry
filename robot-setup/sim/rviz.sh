#!/usr/bin/env bash
# Launch rviz2 with the Scry preset (lidar + camera + tf + map + odom).
#
# Sources ROS + the TurtleBot3 workspace explicitly so that
# `package://turtlebot3_gazebo/...` mesh URIs resolve to the colcon
# install tree. Without the workspace overlay, RViz can't find the
# robot model meshes and shows the "Unable to open file" errors.
set -eo pipefail

set +u
source /opt/ros/jazzy/setup.bash
[ -f /opt/turtlebot3_ws/install/setup.bash ] && source /opt/turtlebot3_ws/install/setup.bash
set -u

# Pass use_sim_time as a node parameter so RViz pulls timestamps off
# Gazebo's /clock — keeps TF buffer aligned with the rest of the stack.
exec rviz2 -d /opt/scry-sim/scry.rviz \
    --ros-args -p use_sim_time:="${USE_SIM_TIME:-true}"
