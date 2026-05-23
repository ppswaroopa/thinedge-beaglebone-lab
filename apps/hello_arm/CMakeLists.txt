cmake_minimum_required(VERSION 3.10)

project(hello_arm)

add_executable(hello_arm main.cpp)

target_link_options(hello_arm PRIVATE
    -static-libstdc++
    -static-libgcc
)
