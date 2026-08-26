#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source /opt/ros/noetic/setup.bash

INSTALL_SETUP="$PROJECT_DIR/ros_workspace/install_isolated/setup.bash"
if [[ ! -f "$INSTALL_SETUP" ]]; then
  echo "未找到构建结果：$INSTALL_SETUP" >&2
  echo "请先运行 ./scripts/build_ros_workspace.sh" >&2
  exit 1
fi
source "$INSTALL_SETUP"

# 运行时只注册本仓库的安装空间和系统 ROS 包，避免源码空间与安装空间重复
# 注册同名包，也避免用户家目录中的其他工程污染 rospack 查询结果。
export ROS_PACKAGE_PATH="$PROJECT_DIR/ros_workspace/install_isolated/share:/opt/ros/noetic/share"

if ! rospack find indoor_active_slam >/dev/null 2>&1; then
  echo "ROS package indoor_active_slam was not found." >&2
  exit 1
fi

roslaunch indoor_active_slam active_slam_indoor_mapping.launch "$@"
