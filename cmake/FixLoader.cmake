# on-platform runtime dependencies: libegl1, xkb-data, libglx0

cmake_policy(SET CMP0140 NEW)

function(variable_name path var_name)
  file(REAL_PATH ${path} abs_path)
  string(REGEX REPLACE "[^A-Za-z0-9_]" "_" ${var_name} ${abs_path})
  return(PROPAGATE ${var_name})
endfunction()

function(fix_rpath_in_folder DIRECTORY INSTALL_PATH)
  set(VAR_NAME)
  set(FILE_TYPE)
  file(REAL_PATH ${DIRECTORY} abs_dir)
  file(GLOB_RECURSE ALL_FILES FOLLOW_SYMLINKS true "${abs_dir}/*")
  foreach(filepath IN LISTS ALL_FILES)
    execute_process(
      COMMAND file --mime-type -b "${filepath}"
      OUTPUT_VARIABLE MIME_TYPE
      RESULT_VARIABLE result
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT ${result} EQUAL 0)
      message(FATAL_ERROR "unable to detect mime type of ${filepath}")
    endif()
    message(DEBUG "${filepath}: ${MIME_TYPE}")
    file(
      CHMOD
      ${filepath}
      PERMISSIONS
      OWNER_READ
      OWNER_WRITE
      OWNER_EXECUTE
      GROUP_READ
      GROUP_WRITE
      GROUP_EXECUTE
      WORLD_READ
      WORLD_WRITE
      WORLD_EXECUTE)
    if(${MIME_TYPE} MATCHES "application/x-(pie-)*executable")
      execute_process(
        COMMAND patchelf --set-interpreter "/lib64/ld-linux-x86-64.so.2"
                "${filepath}"
        RESULT_VARIABLE patch_result
        OUTPUT_VARIABLE patch_output
        ERROR_VARIABLE patch_error)

      if(NOT patch_result EQUAL 0)
        message(
          FATAL_ERROR "Failed to patch interpreter for ${filepath}: ${patch_error}")
      endif()
    endif()
  endforeach()
endfunction()

set(INSTALL_PATH "${CMAKE_INSTALL_PREFIX}")
if(DEFINED CPACK_TEMPORARY_INSTALL_DIRECTORY)
  set(ROOT_DIR
      "${CPACK_TEMPORARY_INSTALL_DIRECTORY}${CPACK_PACKAGING_INSTALL_PREFIX}")
  set(INSTALL_PATH "${CPACK_PACKAGING_INSTALL_PREFIX}")
endif()

if(CMAKE_SCRIPT_MODE_FILE OR DEFINED CPACK_TEMPORARY_INSTALL_DIRECTORY)
  if(${CPACK_GENERATOR} STREQUAL "DEB" OR ${CPACK_GENERATOR} STREQUAL "RPM")
    message(STATUS "Running FixRpath for ${CPACK_GENERATOR} in ${ROOT_DIR}")
    if(EXISTS ${ROOT_DIR})
      fix_rpath_in_folder(${ROOT_DIR} ${INSTALL_PATH})
    endif()
  endif()
endif()
