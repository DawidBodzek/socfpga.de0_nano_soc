cmake_minimum_required(VERSION 3.27)

project(ocm_tester VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -Wall -Wextra -Werror")

find_package(GTest REQUIRED)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")

add_executable(ocm_tester)

target_include_directories(ocm_tester PRIVATE
    include
)

target_link_libraries(ocm_tester PRIVATE
    GTest::gtest
    GTest::gtest_main
)

target_sources(ocm_tester PRIVATE
    src/devmem_test.cpp
    src/driver_test.cpp
)

install(TARGETS ocm_tester
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
