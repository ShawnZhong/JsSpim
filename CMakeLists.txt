cmake_minimum_required(VERSION 3.14)

project(JsSpim)

set(CMAKE_CXX_STANDARD 17)

add_executable(spim spim/spim.cpp)
include_directories(spim/CPU)
include_directories($ENV{EMSCRIPTEN}/system/include/)