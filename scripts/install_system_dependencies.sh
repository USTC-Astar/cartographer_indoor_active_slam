#!/usr/bin/env bash
set -euo pipefail

# ROS 与 Gazebo 属于操作系统级依赖，不能可靠地随 Git 仓库复制；这里统一安装，
# 避免用户按 README 手动猜包名，也避免把本机的二进制缓存提交进仓库。
if [[ "${ROS_DISTRO:-}" != "noetic" ]]; then
  echo "请先安装 ROS Noetic，并执行：source /opt/ros/noetic/setup.bash" >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  build-essential \
  cmake \
  ninja-build \
  pkg-config \
  libboost-iostreams-dev \
  libcairo2-dev \
  libceres-dev \
  libeigen3-dev \
  libgflags-dev \
  libgoogle-glog-dev \
  libgmock-dev \
  libgtest-dev \
  liblua5.2-dev \
  libpcl-dev \
  libprotobuf-dev \
  protobuf-compiler \
  ros-noetic-gazebo-ros-pkgs \
  ros-noetic-geometry-msgs \
  ros-noetic-message-generation \
  ros-noetic-message-runtime \
  ros-noetic-nav-msgs \
  ros-noetic-pcl-conversions \
  ros-noetic-rosbag \
  ros-noetic-roscpp \
  ros-noetic-roslib \
  ros-noetic-rospy \
  ros-noetic-rviz \
  ros-noetic-robot-state-publisher \
  ros-noetic-sensor-msgs \
  ros-noetic-std-msgs \
  ros-noetic-tf2-eigen \
  ros-noetic-tf2-ros \
  ros-noetic-urdf \
  ros-noetic-visualization-msgs \
  ros-noetic-xacro

if command -v rosdep >/dev/null 2>&1; then
  if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    sudo rosdep init
  fi
  rosdep update
  rosdep install \
    --from-paths "$(cd "$(dirname "${BASH_SOURCE[0]}")/../ros_workspace/src" && pwd)" \
    --ignore-src \
    --rosdistro noetic \
    --default-yes \
    --skip-keys libabsl-dev \
    -r
fi

echo "系统依赖安装完成。"
