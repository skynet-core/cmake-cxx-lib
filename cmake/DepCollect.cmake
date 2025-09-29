# on-platform runtime dependencies: libegl1, xkb-data, libglx0

cmake_policy(SET CMP0140 NEW)

function(variable_name path var_name)
  file(REAL_PATH ${path} abs_path)
  string(REGEX REPLACE "[^A-Za-z0-9_]" "_" ${var_name} ${abs_path})
  return(PROPAGATE ${var_name})
endfunction()

function(scan_deps_in_folder DIRECTORY)
  set(VAR_NAME)
  set(FILE_TYPE)
  file(REAL_PATH ${DIRECTORY} abs_dir)
  file(GLOB_RECURSE ALL_FILES FOLLOW_SYMLINKS true "${abs_dir}/*")
  list(LENGTH ALL_FILES len)
  while(${len} GREATER 0)
    list(POP_BACK ALL_FILES last_file)
    variable_name(${last_file} VAR_NAME)
    if(SEEN_${VAR_NAME})
      list(LENGTH ALL_FILES len)
      continue()
    endif()
    set(SEEN_${VAR_NAME} ON)

    # resolve dependencies for every file and append to the TODO list
    execute_process(
      COMMAND file --mime-type -b "${last_file}"
      OUTPUT_VARIABLE MIME_TYPE
      RESULT_VARIABLE result
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT ${result} EQUAL 0)
      message(FATAL_ERROR "unable to detect mime type of ${last_file}")
    endif()
    message(DEBUG "${last_file}: ${MIME_TYPE}")
    get_filename_component(name ${last_file} NAME)
    if(${MIME_TYPE} MATCHES "application/x-(pie-)*executable")
      message(DEBUG "resolve dependencies for ${last_file}")
      file(
        GET_RUNTIME_DEPENDENCIES
        RESOLVED_DEPENDENCIES_VAR
        resolved_deps
        EXECUTABLES
        ${last_file}
        DIRECTORIES
        "${DIRECTORY}/lib"
        "${DIRECTORY}/lib64")
    elseif(${MIME_TYPE} MATCHES "application/x-(pie-)*sharedlib")
      # we have to put this library into lib folder, if it is not plugins
      if(NOT ${last_file} MATCHES ".*/plugins/.*")
        if(NOT EXISTS "${abs_dir}/lib/${name}")
          file(COPY ${last_file} DESTINATION "${abs_dir}/lib")
        endif()
      endif()
      message(DEBUG "resolve dependencies for ${last_file}")
      file(
        GET_RUNTIME_DEPENDENCIES
        RESOLVED_DEPENDENCIES_VAR
        resolved_deps
        LIBRARIES
        ${last_file}
        DIRECTORIES
        "${DIRECTORY}/lib"
        "${DIRECTORY}/lib64")
    elseif("${MIME_TYPE}" STREQUAL "inode/symlink")
      if(${last_file} MATCHES ".*/lib/.*")
        if(NOT EXISTS "${abs_dir}/lib/${name}")
          file(
            COPY ${last_file}
            DESTINATION "${abs_dir}/lib"
            FOLLOW_SYMLINK_CHAIN)
        endif()
      endif()

      file(READ_SYMLINK "${last_file}" any_file)
      if(NOT IS_ABSOLUTE "${any_file}")
        get_filename_component(dir "${last_file}" DIRECTORY)
        set(any_file "${dir}/${any_file}")
      endif()
      list(APPEND ALL_FILES ${any_file})
      continue()
    else()
      list(LENGTH ALL_FILES len)
      continue()
    endif()

    set(filtered)
    foreach(dep IN LISTS resolved_deps)
      variable_name(${dep} VAR_NAME)
      if(NOT SEEN_${VAR_NAME})
        list(APPEND filtered ${dep})
      endif()
    endforeach()
    list(APPEND ALL_FILES ${filtered})
    list(LENGTH ALL_FILES len)
  endwhile()
endfunction()

function(ensure_rpath DIRECTORY INSTALL_PATH)
  file(REAL_PATH ${DIRECTORY} abs_dir)
  file(GLOB_RECURSE ALL_FILES FOLLOW_SYMLINKS true "${abs_dir}/*")

  foreach(file IN LISTS ALL_FILES)
    get_filename_component(name ${file} NAME)

    execute_process(
      COMMAND file --mime-type -b "${file}"
      OUTPUT_VARIABLE MIME_TYPE
      RESULT_VARIABLE result
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT ${result} EQUAL 0)
      message(FATAL_ERROR "unable to detect mime type of ${file}")
    endif()
    message(DEBUG "${file}: ${MIME_TYPE}")

    if(${MIME_TYPE} MATCHES "application/x-(pie-)*executable"
       OR ${MIME_TYPE} MATCHES "application/x-(pie-)*sharedlib")
      set(rpath "\$ORIGIN")
      if(${MIME_TYPE} MATCHES "application/x-(pie-)*executable")
        set(rpath "\$ORIGIN/lib:\$ORIGIN/lib64")
        execute_process(
          COMMAND patchelf --set-interpreter
                  "${INSTALL_PATH}/lib/ld-linux-x86-64.so.2" "${file}"
          RESULT_VARIABLE patch_result
          OUTPUT_VARIABLE patch_output
          ERROR_VARIABLE patch_error)

        if(NOT patch_result EQUAL 0)
          message(
            FATAL_ERROR "Failed to patch RPATH for ${file}: ${patch_error}")
        endif()
      endif()

      if(NOT ${name} MATCHES "ld-linux(.)*.so")
        file(
          CHMOD
          ${file}
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

        execute_process(
          COMMAND patchelf --set-rpath "${rpath}" "${file}"
          RESULT_VARIABLE patch_result
          OUTPUT_VARIABLE patch_output
          ERROR_VARIABLE patch_error)

        if(NOT patch_result EQUAL 0)
          message(
            FATAL_ERROR "Failed to patch RPATH for ${file}: ${patch_error}")
        endif()
      endif()
    endif()

  endforeach()

endfunction()

set(INSTALL_PATH "${ROOT_DIR}")
if(DEFINED CPACK_TEMPORARY_INSTALL_DIRECTORY)
  set(ROOT_DIR
      "${CPACK_TEMPORARY_INSTALL_DIRECTORY}${CPACK_PACKAGING_INSTALL_PREFIX}")
  set(INSTALL_PATH "${CPACK_PACKAGING_INSTALL_PREFIX}")
endif()

if(CMAKE_SCRIPT_MODE_FILE OR DEFINED CPACK_TEMPORARY_INSTALL_DIRECTORY)
  message(STATUS "Running DepCollect for ${ROOT_DIR}")
  if(EXISTS ${ROOT_DIR})
    scan_deps_in_folder(${ROOT_DIR})
    ensure_rpath(${ROOT_DIR} ${INSTALL_PATH})
  endif()
endif()
