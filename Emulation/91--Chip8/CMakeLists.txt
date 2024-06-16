cmake_minimum_required(VERSION 3.18)
include_guard(DIRECTORY)

project(
  chip-8
  VERSION 0.0.1
  LANGUAGES CXX C
)

add_executable(chip-8 Driver.cpp)
