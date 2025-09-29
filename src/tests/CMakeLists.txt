cmake_minimum_required(VERSION 3.31)
file(GLOB TESTS "*_test.cxx")

find_package(Catch2 CONFIG REQUIRED Catch2WithMain)
find_package(Boost CONFIG REQUIRED COMPONENTS headers system url)
foreach(test_file IN LISTS TESTS)
  get_filename_component(name "${test_file}" NAME_WE)
  add_executable(${name} ${test_file})
  target_link_libraries(${name} PRIVATE Catch2::Catch2WithMain http)
  set_target_properties(
    ${name}
    PROPERTIES CXX_STANDARD 23
               CXX_STANDARD_REQUIRED ON
               CXX_EXTENSIONS OFF)
  add_test(NAME ${name} COMMAND ${name})
endforeach()
