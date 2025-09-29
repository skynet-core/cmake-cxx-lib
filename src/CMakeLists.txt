cmake_minimum_required(VERSION 3.31)
include(ExportHelper)

file(GLOB MOD_SRC "*.cxx")

find_package(Threads REQUIRED)
# find_package(Boost CONFIG REQUIRED COMPONENTS headers)
# find_package(OpenSSL REQUIRED SSL Crypto)

add_library(${PROJECT_NAME} SHARED)

target_sources(${PROJECT_NAME} PRIVATE ${MOD_SRC})
install(TARGETS ${PROJECT_NAME})

target_link_libraries(
  ${PROJECT_NAME} PRIVATE Threads::Threads)

add_exported_target(${PROJECT_NAME} SUPPORTED_COMPONENTS)

if(BUILD_TESTING AND ${CMAKE_PROJECT_NAME}_BUILD_TESTING)
  add_subdirectory(tests)
endif()
