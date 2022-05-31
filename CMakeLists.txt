cmake_minimum_required(VERSION 3.0.0)

set(PLUGIN_VERSION 1.1.0)

add_subdirectory(SimpleLibraryViews)

set(CPACK_GENERATOR "ZIP")
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)
set(CPACK_PACKAGE_FILE_NAME "SimpleLibraryViewsNew-${PLUGIN_VERSION}")
include (CPack)
