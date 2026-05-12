#!/usr/bin/env bash
# Launch Nav2 against the running TurtleBot3 sim.
#
# By default uses online SLAM (no pre-built map needed). To use a saved
# map, set MAP=/path/to/map.yaml.
#
# After it's up, in the Scry app you can ask the AI to send a goal pose,
# or use rviz2's "2D Goal Pose" tool.
set -eo pipefail

set +u
source /opt/ros/jazzy/setup.bash
[ -f /opt/turtlebot3_ws/install/setup.bash ] && source /opt/turtlebot3_ws/install/setup.bash
set -u

export TURTLEBOT3_MODEL="${TURTLEBOT3_MODEL:-burger}"

# /cmd_vel type alignment.
#
# Background: in ROS 2 Jazzy, Nav2's controller_server / behavior_server
# / velocity_smoother / collision_monitor / docking_server still publish
# geometry_msgs/Twist by default. TurtleBot3's Gazebo connect config
# (turtlebot3_waffle_bridge.yaml, shipped by ROBOTIS) declares /cmd_vel
# as TwistStamped. The result: /cmd_vel ends up as a multi-typed topic,
# the DDS graph splits, the diff-drive plugin never sees the controller's
# commands, and Nav2 logs "Failed to make progress" on every goal.
#
# Fix: tell every Nav2 node in the cmd_vel chain to publish TwistStamped
# (matches the simulator side). nav2_bringup's launch files take a single
# params_file= and *replace* the default with it, so we copy the upstream
# default and patch in the override rather than maintaining a fork.
#
# If you ever swap to a real TurtleBot3 (which subscribes to plain Twist),
# unset NAV2_STAMPED_CMD_VEL or set it to false.
STAMPED="${NAV2_STAMPED_CMD_VEL:-true}"
DEFAULT_PARAMS="$(ros2 pkg prefix nav2_bringup)/share/nav2_bringup/params/nav2_params.yaml"
PATCHED_PARAMS=/tmp/scry_nav2_params.yaml

cp "${DEFAULT_PARAMS}" "${PATCHED_PARAMS}"

# Inject `enable_stamped_cmd_vel: <STAMPED>` into every node's
# ros__parameters block that owns a cmd_vel publisher. Done in Python
# (not sed/yq) because we don't ship yq in the sim image and editing
# YAML with sed is brittle — Nav2's params file uses anchor merges.
python3 - "${PATCHED_PARAMS}" "${STAMPED}" <<'PYEOF'
import sys
import re
path, stamped = sys.argv[1], sys.argv[2].lower()
nodes = ("controller_server", "behavior_server", "velocity_smoother",
         "collision_monitor", "docking_server")
with open(path) as f:
    text = f.read()
# Strip any existing settings ONCE up-front so we don't double-write; if
# we did this inside the loop, each iteration would wipe the line the
# previous iteration injected.
text = re.sub(
    r"^\s*enable_stamped_cmd_vel:\s*\S+\s*\n",
    "",
    text,
    flags=re.MULTILINE,
)
for node in nodes:
    # Match "<node>:\n  ros__parameters:\n" and inject the param right after.
    pattern = re.compile(
        rf"(^{re.escape(node)}:\s*\n\s*ros__parameters:\s*\n)",
        re.MULTILINE,
    )
    text = pattern.sub(
        rf"\1    enable_stamped_cmd_vel: {stamped}\n",
        text,
        count=1,
    )
with open(path, "w") as f:
    f.write(text)
PYEOF

PARAMS_FILE="${NAV2_PARAMS:-${PATCHED_PARAMS}}"

if [ -n "${MAP:-}" ] && [ -f "${MAP}" ]; then
    echo "[scry-sim] Nav2 with pre-built map: ${MAP}  params: ${PARAMS_FILE}  stamped_cmd_vel=${STAMPED}"
    exec ros2 launch nav2_bringup bringup_launch.py \
        use_sim_time:="${USE_SIM_TIME:-true}" \
        map:="${MAP}" \
        params_file:="${PARAMS_FILE}"
else
    # Nav2 expects a /map source. The standalone `slam` compose service
    # provides it via slam_toolbox. We only launch the navigation stack
    # here (planner + controller + bt_navigator etc.) — no SLAM, no
    # map_server — to avoid duplicate nodes fighting over /map.
    echo "[scry-sim] Nav2 navigation stack (consumes /map from external SLAM)  params: ${PARAMS_FILE}  stamped_cmd_vel=${STAMPED}"
    exec ros2 launch nav2_bringup navigation_launch.py \
        use_sim_time:="${USE_SIM_TIME:-true}" \
        params_file:="${PARAMS_FILE}"
fi
