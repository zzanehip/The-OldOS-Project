cmake_minimum_required (VERSION 2.6)
project (mailcore2) 

IF(APPLE)
  set(CMAKE_CXX__FLAGS "-std=c++11 -stdlib=libc++")
  set(CMAKE_EXE_LINKER_FLAGS "-lc++ -stdlib=libc++")
  
  set(additional_lib_searchpath
    "${CMAKE_CURRENT_SOURCE_DIR}/Externals/ctemplate-osx/lib"
    "${CMAKE_CURRENT_SOURCE_DIR}/Externals/libetpan-osx/lib"
  )
  
  execute_process(COMMAND xcrun --sdk macosx --show-sdk-path OUTPUT_VARIABLE sdkpath)
  string(STRIP "${sdkpath}" sdkpath)
  set(additional_includes
    "${CMAKE_CURRENT_SOURCE_DIR}/Externals/ctemplate-osx/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/Externals/libetpan-osx/include"
    /usr/include/tidy
    /usr/include/libxml2
    "${sdkpath}/usr/include/tidy"
    "${sdkpath}/usr/include/libxml2"
  )
  message(STATUS "${additional_includes}")
  
  set(mac_libraries iconv)
  
ELSEIF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(CMAKE_CXX_FLAGS "-std=gnu++0x")
  
  set(additional_includes
    /usr/include/tidy
    /usr/include/libxml2
  )
  
  set(icu_libraries icudata icui18n icuio icule iculx icutest icutu icuuc)
  set(linux_libraries ${icu_libraries} pthread uuid)
ENDIF()


IF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  find_package(PkgConfig)
  pkg_check_modules (GLIB2 glib-2.0)
ENDIF()

IF(APPLE)
    find_library(FOUNDATIONFRAMEWORK NAMES Foundation)
    find_library(SECURITYFRAMEWORK NAMES Security)
    find_library(CORESERVICESFRAMEWORK NAMES CoreServices)
ENDIF()

if(NOT APPLE)
  
  # detect icu

  find_path(ICU4C_INCLUDE_DIR
    NAMES unicode/utf8.h
    PATHS ${additional_includes}
  )
  find_library(ICU4C_LIBRARY
    NAMES icudata icui18n icuio icule iculx icutest icutu icuuc
    PATHS ${additional_lib_searchpath}
  )

  if(NOT ICU4C_INCLUDE_DIR OR NOT ICU4C_LIBRARY)
    message(FATAL_ERROR "ERROR: Could not find icu4c")
  else()
    message(STATUS "Found icu4c")
  endif()
  
endif()

IF(ANDROID)
  message(STATUS "Android platform")
ELSE()

# detect ctemplate

find_path(CTEMPLATE_INCLUDE_DIR
  NAMES ctemplate/template.h
  PATHS ${additional_includes}
)
find_library(CTEMPLATE_LIBRARY
  NAMES ctemplate
  PATHS ${additional_lib_searchpath}
)

if(NOT CTEMPLATE_INCLUDE_DIR OR NOT CTEMPLATE_LIBRARY)
  message(FATAL_ERROR "ERROR: Could not find ctemplate")
else()
  message(STATUS "Found ctemplate")
endif()


# detect libetpan

find_path(LIBETPAN_INCLUDE_DIR
  NAMES libetpan/libetpan.h
  PATHS ${additional_includes}
)
find_library(LIBETPAN_LIBRARY
  NAMES etpan
  PATHS ${additional_lib_searchpath}
)

if(NOT LIBETPAN_INCLUDE_DIR OR NOT LIBETPAN_LIBRARY)
  message(FATAL_ERROR "ERROR: Could not find libetpan")
else()
  message(STATUS "Found libetpan")
endif()


# detect tidy

find_path(TIDY_INCLUDE_DIR
  NAMES tidy.h
  PATHS ${additional_includes}
)
find_library(TIDY_LIBRARY
  NAMES tidy
  PATHS ${additional_lib_searchpath}
)

if(NOT TIDY_INCLUDE_DIR OR NOT TIDY_LIBRARY)
  message(FATAL_ERROR "ERROR: Could not find tidy")
else()
  message(STATUS "Found tidy")
endif()


# detect uuid

find_path(UUID_INCLUDE_DIR
  NAMES uuid/uuid.h
  PATHS ${additional_includes}
)

if(NOT UUID_INCLUDE_DIR)
  message(FATAL_ERROR "ERROR: Could not find uuid")
else()
  message(STATUS "Found uuid")
endif()


# detect libxml2

find_path(LIBXML_INCLUDE_DIR
  NAMES libxml/xmlreader.h
  PATHS ${additional_includes}
)
find_library(LIBXML_LIBRARY
  NAMES xml2
  PATHS ${additional_lib_searchpath}
)

if(NOT LIBXML_INCLUDE_DIR OR NOT LIBXML_LIBRARY)
  message(FATAL_ERROR "ERROR: Could not find libxml2")
else()
  message(STATUS "Found libxml2")
endif()


# detect zlib

find_path(ZLIB_INCLUDE_DIR
  NAMES zlib.h
  PATHS ${additional_includes}
)
find_library(ZLIB_LIBRARY
  NAMES z
  PATHS ${additional_lib_searchpath}
)

if(NOT ZLIB_INCLUDE_DIR OR NOT ZLIB_LIBRARY)
  message(FATAL_ERROR "ERROR: Could not find zlib")
else()
  message(STATUS "Found zlib")
endif()

ENDIF() # Android platform

add_subdirectory (src)
add_subdirectory (tests)
add_subdirectory (unittest)

