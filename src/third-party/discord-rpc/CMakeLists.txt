cmake_minimum_required(VERSION 3.5...3.28)
project (DiscordRPC)

include(GNUInstallDirs)

# format
file(GLOB_RECURSE ALL_SOURCE_FILES
    include/*.h
    src/*.cpp src/*.h src/*.c
)

# add subdirs

add_subdirectory(src)
