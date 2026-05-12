#!/usr/bin/env bash
# Launch a TurtleBot3 in Gazebo Harmonic.
#
# Env vars:
#   WORLD              TURTLEBOT3_WORLD | HOUSE | EMPTY  (default: TURTLEBOT3_WORLD)
#   TURTLEBOT3_MODEL   burger | waffle | waffle_pi       (default: burger)
# ROS setup.bash references unset vars (e.g. AMENT_TRACE_SETUP_FILES) so
# we have to drop `-u` while sourcing it, then turn safety back on.
set -eo pipefail

set +u
source /opt/ros/jazzy/setup.bash
[ -f /opt/turtlebot3_ws/install/setup.bash ] && source /opt/turtlebot3_ws/install/setup.bash
set -u

export TURTLEBOT3_MODEL="${TURTLEBOT3_MODEL:-burger}"
WORLD="${WORLD:-TURTLEBOT3_WORLD}"

echo "[scry-sim] model=${TURTLEBOT3_MODEL}  world=${WORLD}"

case "${WORLD^^}" in
    EMPTY)
        LAUNCH="empty_world.launch.py"
        ;;
    HOUSE)
        LAUNCH="turtlebot3_house.launch.py"
        ;;
    TURTLEBOT3_WORLD|*)
        LAUNCH="turtlebot3_world.launch.py"
        ;;
esac

# turtlebot3_gazebo's launch files target Gazebo Harmonic on Jazzy.
# If your branch is older and only ships Classic launch files, fall back.
if ros2 pkg prefix turtlebot3_gazebo >/dev/null 2>&1; then
    exec ros2 launch turtlebot3_gazebo "${LAUNCH}"
else
    echo "[scry-sim] turtlebot3_gazebo not found — workspace not built?" >&2
    exit 1
fi
