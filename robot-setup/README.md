# robot-setup

Three Docker stacks live here, picked by purpose:

| File | Purpose |
|------|---------|
| `Dockerfile` + `docker-compose.yml` | Production install: ROS Humble + scry-connect only. What runs on the actual robot. |
| `Dockerfile.dev` + `docker-compose.dev.yml` | Dev sandbox: Humble desktop-full + turtlesim + connect in editable mode. Quick smoke testing. |
| `Dockerfile.sim` + `docker-compose.sim.yml` | **Full-stack sim** (this doc): ROS 2 Jazzy + Gazebo Harmonic + TurtleBot3 + Nav2 + SLAM. End-to-end app testing with a moving robot, lidar, camera, odometry. |

---

## Full-stack sim — quick start

End-to-end test of the Scry app against a TurtleBot3 driving in Gazebo, publishing real `/scan`, `/camera/image_raw`, `/odom`, `/cmd_vel`, `/tf` topics.

### 1. One-time build (~30–45 min, ~7 GB)

```bash
xhost +local:docker                              # let containers reach your X server
cd robot-setup
docker compose -f docker-compose.sim.yml build
```

The build clones TurtleBot3 from source (the `jazzy` branch — there is no apt release for Jazzy yet) and `colcon build`s it inside the image.

### 2. Start the sim + connect

```bash
docker compose -f docker-compose.sim.yml up sim connect
```

You should see Gazebo open with a TurtleBot3 in the obstacle world. The connect starts on **`<host-ip>:5339`** — point the Scry app there.

### 3. Drive the robot

```bash
docker exec -it scry-sim /opt/scry-sim/teleop.sh
```

`w/a/s/d/x` moves and stops. While it moves, `/scan`, `/odom`, `/cmd_vel` all update — the app's lidar viewer, topic monitor, and AI chat have something real to look at.

### 4. Optional layers (profiles)

Run any of these in **separate terminals**, alongside `sim` + `connect`:

```bash
# RViz with a pre-loaded view (lidar + camera + tf + map):
docker compose -f docker-compose.sim.yml --profile rviz up rviz

# SLAM Toolbox — drives /map while you teleop:
docker compose -f docker-compose.sim.yml --profile slam up slam

# Nav2 — set a goal pose from RViz or the app and watch it plan:
docker compose -f docker-compose.sim.yml --profile nav up nav
```

### 5. Knobs

Set these as env vars before `up` (or in a `.env` file next to the compose):

| Var | Values | Default |
|-----|--------|---------|
| `WORLD` | `TURTLEBOT3_WORLD`, `HOUSE`, `EMPTY` | `TURTLEBOT3_WORLD` |
| `TURTLEBOT3_MODEL` | `burger`, `waffle`, `waffle_pi` | `burger` |
| `ROS_DOMAIN_ID` | 0–101 | `0` |
| `LIBGL_ALWAYS_SOFTWARE` | `0`/`1` (set `1` if Gazebo's GPU access is misbehaving) | `0` |

`waffle_pi` ships a camera; `burger` is lidar-only. Use `waffle_pi` to test the app's image viewer.

### 6. Tear down

```bash
docker compose -f docker-compose.sim.yml down
xhost -local:docker
```

---

## Topics published by the sim

| Topic | Type | Notes |
|-------|------|-------|
| `/scan` | `sensor_msgs/LaserScan` | 360° lidar (1° resolution on burger) |
| `/odom` | `nav_msgs/Odometry` | Wheel odometry from `diff_drive` |
| `/imu` | `sensor_msgs/Imu` | Body-frame IMU |
| `/camera/image_raw` | `sensor_msgs/Image` | `waffle_pi` only |
| `/cmd_vel` | `geometry_msgs/Twist` | Subscribed by the robot |
| `/tf`, `/tf_static` | `tf2_msgs/TFMessage` | Full transform tree |
| `/joint_states` | `sensor_msgs/JointState` | Wheel joints |
| `/map` | `nav_msgs/OccupancyGrid` | Only when `slam` profile is up |

This matches the topic shape of a real TurtleBot3 deployment closely enough that anything the app does against the sim will work against hardware too.

---

## Troubleshooting

**Gazebo opens but stays black.** Set `LIBGL_ALWAYS_SOFTWARE=1` and re-`up`. Common on systems without Mesa drivers exposed to the container.

**`xhost` errors / Gazebo can't connect to display.** Re-run `xhost +local:docker` before `up`. On Wayland-only systems, also set `QT_QPA_PLATFORM=xcb`.

**App can't see topics.** The sim and connect both use `network_mode: host` and the same `ROS_DOMAIN_ID`. From the host: `ros2 topic list` (after sourcing `/opt/ros/jazzy/setup.bash`) should show `/scan` etc. If it doesn't, check `RMW_IMPLEMENTATION` is the same in both places.

**Build fails on `turtlebot3_simulations` / `jazzy` branch.** ROBOTIS may not have published a `jazzy` branch on every repo. The Dockerfile already falls back to `main` for that one repo. If `turtlebot3` or `turtlebot3_msgs` itself fails, edit `Dockerfile.sim` to use `main` for those too — those packages are fairly distro-stable.
