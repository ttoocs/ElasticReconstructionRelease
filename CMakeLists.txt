cmake_minimum_required(VERSION 2.6 FATAL_ERROR)

project(ONI_STUFF)

#set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules/" ${CMAKE_MODULE_PATH})

add_definitions(
  -g
#  -O2
)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY  ${CMAKE_SOURCE_DIR}/bin)

#Git init/updates
macro(gitInit)
  execute_process ( COMMAND git submodule init ${CMAKE_CURRENT_SOURCE_DIR}/${argv} )
  execute_process ( COMMAND git submodule update ${CMAKE_CURRENT_SOURCE_DIR}/${argv} )
endmacro()

gitInit( SeperateKinfu )
gitInit( OpenNi-Stuff )
gitInit( ElasticReconstruction )
gitInit( pcl )


#Setup seperate kinfu
execute_process ( COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/SeperateKinfu/symlink.sh ../pcl )

#Build it
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/SeperateKinfu)

#Build recording app
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/OpenNi-Stuff)

#Build Pipeline
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/ElasticReconstruction)

