# Cartographer Indoor Active SLAM

这是一个可复现的室内二维主动建图示例：使用 Gazebo 模拟差速机器人和二维激光雷达，使用 Cartographer 进行 SLAM（Simultaneous Localization and Mapping，同时定位与建图），再由仓库内的主动探索节点自动选择前沿区域并驱动车辆覆盖未知空间。

## 项目特点

- 内置 Cartographer、`cartographer_ros`、消息包和 RViz 插件源码，不依赖用户家目录中的其他工作空间。
- 内置两套 Gazebo 场景：`quick` 适合快速验证，`detailed` 是默认的双卧室室内场景。
- 内置主动 SLAM 前沿检测、可达路径规划、局部避障、碰撞恢复和完成判定逻辑。
- 启动脚本只使用本仓库的 ROS 包路径，不会再次触发“`rospack` 扫描整个 `$HOME`”的问题。

## 目录结构

```text
cartographer_indoor_active_slam/
├── README.md
├── LICENSE
├── .gitignore
├── scripts/
│   ├── install_system_dependencies.sh
│   ├── build_ros_workspace.sh
│   └── run_active_slam_demo.sh
├── third_party/abseil-cpp/            # 固定版本的 Abseil C++ 源码
└── ros_workspace/src/
    ├── cartographer/                 # Cartographer 核心库
    ├── cartographer_ros/              # ROS 节点和 launch 资源
    ├── cartographer_ros_msgs/         # Cartographer 消息与服务
    ├── cartographer_rviz/              # RViz 插件
    └── indoor_active_slam/             # 本项目机器人、场景和主动探索代码
        ├── config/
        ├── launch/active_slam_indoor_mapping.launch
        ├── rviz/active_slam_mapping.rviz
        ├── scripts/
        ├── urdf/active_slam_robot.urdf.xacro
        └── worlds/
```

## 环境要求

推荐使用以下基线，避免 ROS 版本差异导致编译问题：

- Ubuntu 20.04（Focal）
- ROS Noetic Desktop（包含 `roscore`、RViz 和 Gazebo）
- 至少 8 GB 内存和约 8 GB 可用磁盘空间
- 已安装 `git`、`sudo` 和可用的 Ubuntu/ROS 软件源

Cartographer 核心源码和本项目代码已经随仓库提供；Ubuntu 与 ROS 的系统库仍需通过包管理器安装，这是 Linux 项目的正常做法，不能把 `/opt/ros` 这样的系统目录安全地复制进 Git 仓库。

## 从零复现

```bash
git clone https://github.com/USTC-Astar/cartographer_indoor_active_slam.git
cd cartographer_indoor_active_slam

source /opt/ros/noetic/setup.bash
./scripts/install_system_dependencies.sh
./scripts/build_ros_workspace.sh
./scripts/run_active_slam_demo.sh
```

如果你的远程仓库已经改名，请把上面的 clone 地址替换成新的 GitHub 地址；本地目录名不影响构建。

首次编译会花费几分钟。正常情况下，终端会看到类似以下信息：

`build_ros_workspace.sh` 会自动隔离当前终端中其他 ROS 工作空间的环境变量，因此即使之前 source 过其他项目，也不会把它们的同名包加入本项目构建。

```text
Spawned active_slam_robot at x=-3.00 y=-4.70 yaw=0.00
```

随后会打开 Gazebo 和 RViz。RViz 中可以看到地图、激光扫描、机器人、主动探索前沿、当前路径和目标点。

## 常用运行方式

所有命令均在仓库根目录执行：

```bash
# 小场景，适合检查代码和快速验证
./scripts/run_active_slam_demo.sh scene:=quick

# 默认的大型双卧室场景
./scripts/run_active_slam_demo.sh scene:=detailed

# 无 Gazebo 图形界面运行，适合远程机器
./scripts/run_active_slam_demo.sh gui:=false rviz:=false

# 只启动建图，不启动主动探索
./scripts/run_active_slam_demo.sh autonomous:=false active_slam:=false
```

停止程序时在终端按 `Ctrl-C`。无界面模式下，地图数据通过 ROS 话题发布，可用 `rostopic list` 和 `rostopic echo /map` 检查。

## 主要 ROS 话题

主动探索节点主要发布：

```text
/active_slam/status
/active_slam/frontiers
/active_slam/path
/active_slam/target
/active_slam/costmap
/active_slam/completed
```

Cartographer 建图结果主要发布在 `/map`，机器人激光扫描在 `/scan`，经过时间戳过滤的里程计在 `/cartographer/odom`。

## 验证命令

构建后可先不启动 Gazebo，检查 ROS 包是否来自本仓库：

```bash
source /opt/ros/noetic/setup.bash
source ros_workspace/install_isolated/setup.bash
rospack find cartographer
rospack find cartographer_ros
rospack find indoor_active_slam
```

三条命令应分别返回 `ros_workspace/src` 对应的安装路径。检查启动文件解析：

```bash
roslaunch --nodes indoor_active_slam active_slam_indoor_mapping.launch
```

正常情况下会列出 `cartographer_node`、`cartographer_occupancy_grid_node`、`active_slam_frontier_explorer` 等节点名称，但不会真正启动 Gazebo。

## 已知限制

- 本项目目标平台是 ROS Noetic；没有为 ROS 2 或其他 ROS 发行版维护同一套构建配置。
- Gazebo 图形界面需要本机桌面或正确配置的 X11/远程桌面；服务器环境请使用 `gui:=false rviz:=false`。
- 编译依赖通过 `install_system_dependencies.sh` 安装，运行时不需要 `~/cartographer_ws`、`~/cartographer_ws_v2` 或其他外部工作空间。

## 第三方源码与许可证

`ros_workspace/src/cartographer`、`cartographer_ros`、`cartographer_ros_msgs`、`cartographer_rviz` 和 `third_party/abseil-cpp` 保留各自的 Apache 2.0 许可证文件和上游版权声明。本项目自身也采用 Apache 2.0，详见 `LICENSE`。

内置版本：

- [Cartographer](https://github.com/cartographer-project/cartographer)：`877157a0d91788a7700221d87232d412cb3c1ef4`
- [`cartographer_ros`](https://github.com/cartographer-project/cartographer_ros)：`c138034db0c47fe0ea5a2abe516acae02190dbf5`
- [Abseil C++](https://github.com/abseil/abseil-cpp)：`215105818dfde3174fe799600bb0f3cae233d0bf`（20211102.0）

以上提交已于 2026-08-26 通过官方 GitHub 仓库远程引用核对。
