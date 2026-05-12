#!/usr/bin/env bash
# Drive the simulated TurtleBot3 from the keyboard.
#
# Run inside the sim container:
#   docker exec -it scry-sim /opt/scry-sim/teleop.sh
#
# Keys: w/a/s/d/x = forward/left/back/right/stop. Hold Shift for full speed.
set -eo pipefail

set +u
source /opt/ros/jazzy/setup.bash
[ -f /opt/turtlebot3_ws/install/setup.bash ] && source /opt/turtlebot3_ws/install/setup.bash
set -u

export TURTLEBOT3_MODEL="${TURTLEBOT3_MODEL:-burger}"

exec ros2 run turtlebot3_teleop teleop_keyboard
