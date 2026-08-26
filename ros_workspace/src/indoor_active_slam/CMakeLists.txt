cmake_minimum_required(VERSION 3.0.2)
project(indoor_active_slam)

find_package(catkin REQUIRED)
catkin_package()

catkin_install_python(PROGRAMS
  scripts/active_slam_frontier_explorer.py
  scripts/cartographer_odom_filter.py
  scripts/spawn_mapping_robot.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

install(DIRECTORY config launch rviz urdf worlds
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
)
