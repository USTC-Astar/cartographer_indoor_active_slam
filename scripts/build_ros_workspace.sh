#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_DIR="$PROJECT_DIR/ros_workspace"
ABSEIL_SOURCE_DIR="$PROJECT_DIR/third_party/abseil-cpp"
ABSEIL_BUILD_DIR="$PROJECT_DIR/third_party/build/abseil-cpp"
ABSEIL_INSTALL_DIR="$PROJECT_DIR/third_party/install/abseil"

if [[ "${ROS_DISTRO:-}" != "noetic" ]]; then
  echo "请先执行：source /opt/ros/noetic/setup.bash" >&2
  exit 1
fi
if ! command -v catkin_make_isolated >/dev/null 2>&1; then
  echo "未找到 catkin_make_isolated，请先安装 ROS Noetic。" >&2
  exit 1
fi

# Ubuntu 20.04 的常见软件源不提供 Cartographer 所需版本的 libabsl-dev，
# 因此在仓库内固定 Abseil 20211102.0，并安装到项目私有目录而不是 /usr/local。
if [[ ! -f "$ABSEIL_INSTALL_DIR/lib/cmake/absl/abslConfig.cmake" ]]; then
  cmake \
    -S "$ABSEIL_SOURCE_DIR" \
    -B "$ABSEIL_BUILD_DIR" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_INSTALL_PREFIX="$ABSEIL_INSTALL_DIR" \
    -DABSL_BUILD_TESTING=OFF
  cmake --build "$ABSEIL_BUILD_DIR" --parallel
  cmake --install "$ABSEIL_BUILD_DIR"
fi

CMAKE_PREFIX_PATH_ENV="$WORKSPACE_DIR/install_isolated:$ABSEIL_INSTALL_DIR:${CMAKE_PREFIX_PATH:-}"
CMAKE_PREFIX_PATH_CMAKE="${CMAKE_PREFIX_PATH_ENV//:/;}"
export CMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH_ENV"

# CMake 会缓存失败的 *_DIR-NOTFOUND；清掉失败的消息包缓存后才能在同一台机器
# 上重试，否则即使依赖已经安装，旧缓存仍会让配置阶段继续失败。
if [[ -f "$WORKSPACE_DIR/build_isolated/cartographer_ros_msgs/CMakeCache.txt" ]] && \
   grep -q 'message_generation_DIR:PATH=.*NOTFOUND' \
     "$WORKSPACE_DIR/build_isolated/cartographer_ros_msgs/CMakeCache.txt"; then
  find "$WORKSPACE_DIR/build_isolated/cartographer_ros_msgs" -depth -delete
fi
if [[ -f "$WORKSPACE_DIR/build_isolated/cartographer_ros/CMakeCache.txt" ]] && \
   grep -q 'cartographer_ros_msgs_DIR:PATH=.*NOTFOUND' \
     "$WORKSPACE_DIR/build_isolated/cartographer_ros/CMakeCache.txt"; then
  find "$WORKSPACE_DIR/build_isolated/cartographer_ros" -depth -delete
fi

cd "$WORKSPACE_DIR"

# 使用仓库内的 src，并把构建产物固定在 ros_workspace 下；这样运行脚本不会
# 读取用户家目录中其他项目的 ROS_PACKAGE_PATH，避免 rospack 扫描脏 package.xml。
catkin_make_isolated \
  --install \
  --use-ninja \
  --source-space src \
  --build-space build_isolated \
  --devel-space devel_isolated \
  --install-space install_isolated \
  --cmake-args \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH_CMAKE" \
    -DBUILD_GRPC=OFF \
    -DBUILD_PROMETHEUS=OFF \
    -DBUILD_TESTING=OFF \
    -DCATKIN_ENABLE_TESTING=OFF

echo "ROS 工作空间构建完成。"
echo "运行：$PROJECT_DIR/scripts/run_active_slam_demo.sh"
