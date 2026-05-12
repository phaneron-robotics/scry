#!/usr/bin/env bash
# Frontier-based autonomous exploration with explore_lite (m-explore-ros2).
#
# explore_lite subscribes to /map (from slam_toolbox), finds the nearest
# unexplored frontier, and dispatches goals to Nav2's NavigateToPose
# action server. The robot drives itself around and the map fills in.
#
# Required upstream nodes (started by docker-compose.sim.yml):
#   - sim   → TurtleBot3 in Gazebo (publishes /scan, /odom, /tf, /cmd_vel)
#   - slam  → slam_toolbox (publishes /map, map→odom TF)
#   - nav   → Nav2 lifecycle stack (NavigateToPose action, costmaps)
#
# Topic / frame contract — all defaults match TurtleBot3 + Nav2 + SLAM
# Toolbox out of the box, so no remappings are needed:
#   /scan          (sensor_msgs/LaserScan)        — Gazebo lidar
#   /odom          (nav_msgs/Odometry)            — diff-drive plugin
#   /cmd_vel       (geometry_msgs/Twist)          — Nav2 controller
#   /tf, /tf_static                               — robot_state_publisher + Nav2
#   /map           (nav_msgs/OccupancyGrid)       — slam_toolbox
#   /navigate_to_pose (action)                    — Nav2 bt_navigator
#
# explore_lite expects the TF chain  map → odom → base_link  to be live
# before it starts pushing goals. We sleep before launching to give
# slam_toolbox + Nav2 time to come up; the node itself also retries
# internally if /map isn't there yet.
set -eo pipefail

set +u
source /opt/ros/jazzy/setup.bash
[ -f /opt/turtlebot3_ws/install/setup.bash ] && source /opt/turtlebot3_ws/install/setup.bash
set -u

export TURTLEBOT3_MODEL="${TURTLEBOT3_MODEL:-burger}"

if ! ros2 pkg prefix explore_lite >/dev/null 2>&1; then
    echo "[scry-sim] explore_lite not found — was the workspace rebuilt?" >&2
    echo "[scry-sim] tip: docker compose -f docker-compose.sim.yml build" >&2
    exit 1
fi

# Wait for the upstream stack to actually be alive before launching the
# explorer. explore_lite retries internally, but checking explicitly
# turns "Action server not available" log spam into a clear startup
# message and surfaces real failures (e.g. Nav2 lifecycle stuck in
# inactive) instead of a permanently-spinning explorer.
echo "[scry-sim] waiting for /map …"
for _ in $(seq 1 60); do
    if ros2 topic list 2>/dev/null | grep -q '^/map$'; then
        break
    fi
    sleep 1
done

echo "[scry-sim] waiting for /navigate_to_pose action server …"
for _ in $(seq 1 60); do
    if ros2 action list 2>/dev/null | grep -q '^/navigate_to_pose$'; then
        break
    fi
    sleep 1
done

# explore_lite tuning. Defaults are conservative for sim — small frontier
# threshold so it picks up tight TurtleBot3 corridors, and a short
# planner_frequency so it reacts quickly when nav goals fail.
exec ros2 launch explore_lite explore.launch.py \
    use_sim_time:="${USE_SIM_TIME:-true}"
