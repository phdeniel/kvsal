cmake_minimum_required(VERSION 2.6.4)
cmake_policy(SET CMP0017 NEW)

PROJECT(libkvsal C)
set(LIBKVSAL_MAJOR_VERSION 1)
set(LIBKVSAL_MINOR_VERSION 3)
set(LIBKVSAL_PATCH_LEVEL 0)
set(LIBKVSAL_EXTRA_VERSION "")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -I${CMAKE_SOURCE_DIR}/include -fPIC -g")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Werror")

set(LIBKVSAL_BASE_VERSION ${LIBKVSAL_MAJOR_VERSION}.${LIBKVSAL_MINOR_VERSION}.${LIBKVSAL_PATCH_LEVEL})

message( STATUS "cmake version ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}" )
message( STATUS "libkvsal version ${LIBKVSAL_BASE_VERSION}")

# Final tuning

include(CheckIncludeFiles)
include(CheckLibraryExists)

## Check ini_config
check_include_files("ini_config.h" HAVE_INI_CONFIG_H)
find_library(HAVE_INI_CONFIG ini_config)
check_library_exists(
	ini_config
	config_from_file
	""
	HAVE_INI_CONFIG
	)

if((NOT HAVE_INI_CONFIG) OR (NOT HAVE_INI_CONFIG_H))
      message(FATAL_ERROR "Cannot find ini_config")
endif((NOT HAVE_INI_CONFIG) OR (NOT HAVE_INI_CONFIG_H))

## Check for MOTR
find_library(HAVE_MOTR motr)
check_library_exists(
        motr
        m0_init
        ""
        HAVE_MOTR
	)
check_include_files("motr/config.h" HAVE_MOTR_H)

## Check for HIREDIS ##

find_library(HAVE_HIREDIS hiredis)
check_library_exists(
    hiredis
    redisCommand
    ""
    HAVE_HIREDIS
    )
check_include_files("hiredis/hiredis.h" HAVE_HIREDIS_H)

if (HAVE_HIREDIS_H AND HAVE_HIREDIS)
	set(BCOND_REDIS "%bcond_without")
else (HAVE_HIREDIS_H AND HAVE_HIREDIS)
	set(BCOND_REDIS "%bcond_with")
endif (HAVE_HIREDIS_H AND HAVE_HIREDIS)


if (HAVE_MOTR_H AND HAVE_MOTR)
	set(BCOND_MOTR "%bcond_without")
else (HAVE_MOTR_H AND HAVE_MOTR)
	set(BCOND_MOTR "%bcond_with")
endif (HAVE_MOTR_H AND HAVE_MOTR)

if (HAVE_HIREDIS_H AND HAVE_HIREDIS)
	set(HAVE_KVS TRUE)
endif (HAVE_HIREDIS_H AND HAVE_HIREDIS)

if (HAVE_MOTR_H AND HAVE_MOTR)
	set(HAVE_KVS TRUE)
endif (HAVE_MOTR_H AND HAVE_MOTR)

if (NOT HAVE_KVS)
	message(FATAL_ERROR "Can't find a KVS")
endif (NOT HAVE_KVS)

if((HAVE_MOTR) AND (HAVE_MOTR_H))
      message(STATUS "Motr was found, looking for m0common")
        find_library(HAVE_M0COMMON m0common)
        check_library_exists(
                m0common
                m0init
                ""
                HAVE_M0COMMON
                )
endif((HAVE_MOTR) AND (HAVE_MOTR_H))


# Build ancillary libs
add_subdirectory(kvsal)

# CPack / rpmbuild specific stuff
set(CPACK_PACKAGE_FILE_NAME "libkvsal-Source" )
set(CPACK_PACKAGE_VENDOR "KVSAL")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "KVSAL - an abstraction for a KVS to be used by the KVSNS lib ")
SET(CPACK_PACKAGE_VERSION_MAJOR ${LIBKVSAL_MAJOR_VERSION})
SET(CPACK_PACKAGE_VERSION_MINOR ${LIBKVSAL_MINOR_VERSION})
SET(CPACK_PACKAGE_VERSION_PATCH ${LIBKVSAL_PATCH_LEVEL})

# Tell CPack the kind of packages to be generated
set(CPACK_GENERATOR "TGZ")
set(CPACK_SOURCE_GENERATOR "TGZ")

set(CPACK_SOURCE_IGNORE_FILES
  "/.git/;/.gitignore/;/build/;/.bzr/;~$;${CPACK_SOURCE_IGNORE_FILES}")

include(CPack)

set(PKG_NAME "${CPACK_PACKAGE_NAME}.tar.gz")
add_custom_target(dist COMMAND ${CMAKE_MAKE_PROGRAM} package_source)

# Create the .pc file
configure_file(
  "${PROJECT_SOURCE_DIR}/libkvsal.pc-in.cmake"
  "${PROJECT_SOURCE_DIR}/libkvsal.pc"
)

# Now create a useable specfile
configure_file(
  "${PROJECT_SOURCE_DIR}/libkvsal.spec-in.cmake"
  "${PROJECT_SOURCE_DIR}/libkvsal.spec"
)

set(RPMDEST "--define '_srcrpmdir ${CMAKE_CURRENT_BINARY_DIR}'")

add_custom_target( rpms DEPENDS dist)
add_custom_command(TARGET rpms
                  COMMAND sh -c "rpmbuild ${RPMDEST} -ta ${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.gz"
                  VERBATIM
                  DEPENDS dist)

add_custom_target( rpm DEPENDS dist)
add_custom_command(TARGET rpm
                  COMMAND sh -c "rpmbuild ${RPMDEST} -tb ${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.gz"
                  VERBATIM
                  DEPENDS dist)

add_custom_target( srpm DEPENDS dist)
add_custom_command(TARGET srpm
                  COMMAND sh -c "rpmbuild ${RPMDEST} -ts ${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.gz"
                  VERBATIM
                  DEPENDS dist)

# INSTALL
install(FILES ${PROJECT_SOURCE_DIR}/libkvsal.pc DESTINATION lib)
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/kvsal DESTINATION include)
