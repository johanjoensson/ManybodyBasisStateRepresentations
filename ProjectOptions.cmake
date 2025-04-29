include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(ManybodyBasisStateRepresentations_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(ManybodyBasisStateRepresentations_setup_options)
  option(ManybodyBasisStateRepresentations_ENABLE_HARDENING "Enable hardening" ON)
  option(ManybodyBasisStateRepresentations_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    ManybodyBasisStateRepresentations_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    ManybodyBasisStateRepresentations_ENABLE_HARDENING
    OFF)

  ManybodyBasisStateRepresentations_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR ManybodyBasisStateRepresentations_PACKAGING_MAINTAINER_MODE)
    option(ManybodyBasisStateRepresentations_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(ManybodyBasisStateRepresentations_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_PCH "Enable precompiled headers" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(ManybodyBasisStateRepresentations_ENABLE_IPO "Enable IPO/LTO" ON)
    option(ManybodyBasisStateRepresentations_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(ManybodyBasisStateRepresentations_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(ManybodyBasisStateRepresentations_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(ManybodyBasisStateRepresentations_ENABLE_PCH "Enable precompiled headers" OFF)
    option(ManybodyBasisStateRepresentations_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      ManybodyBasisStateRepresentations_ENABLE_IPO
      ManybodyBasisStateRepresentations_WARNINGS_AS_ERRORS
      ManybodyBasisStateRepresentations_ENABLE_USER_LINKER
      ManybodyBasisStateRepresentations_ENABLE_SANITIZER_ADDRESS
      ManybodyBasisStateRepresentations_ENABLE_SANITIZER_LEAK
      ManybodyBasisStateRepresentations_ENABLE_SANITIZER_UNDEFINED
      ManybodyBasisStateRepresentations_ENABLE_SANITIZER_THREAD
      ManybodyBasisStateRepresentations_ENABLE_SANITIZER_MEMORY
      ManybodyBasisStateRepresentations_ENABLE_UNITY_BUILD
      ManybodyBasisStateRepresentations_ENABLE_CLANG_TIDY
      ManybodyBasisStateRepresentations_ENABLE_CPPCHECK
      ManybodyBasisStateRepresentations_ENABLE_COVERAGE
      ManybodyBasisStateRepresentations_ENABLE_PCH
      ManybodyBasisStateRepresentations_ENABLE_CACHE)
  endif()

  ManybodyBasisStateRepresentations_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (ManybodyBasisStateRepresentations_ENABLE_SANITIZER_ADDRESS OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_THREAD OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(ManybodyBasisStateRepresentations_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(ManybodyBasisStateRepresentations_global_options)
  if(ManybodyBasisStateRepresentations_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    ManybodyBasisStateRepresentations_enable_ipo()
  endif()

  ManybodyBasisStateRepresentations_supports_sanitizers()

  if(ManybodyBasisStateRepresentations_ENABLE_HARDENING AND ManybodyBasisStateRepresentations_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_UNDEFINED
       OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_ADDRESS
       OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_THREAD
       OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${ManybodyBasisStateRepresentations_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${ManybodyBasisStateRepresentations_ENABLE_SANITIZER_UNDEFINED}")
    ManybodyBasisStateRepresentations_enable_hardening(ManybodyBasisStateRepresentations_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(ManybodyBasisStateRepresentations_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(ManybodyBasisStateRepresentations_warnings INTERFACE)
  add_library(ManybodyBasisStateRepresentations_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  ManybodyBasisStateRepresentations_set_project_warnings(
    ManybodyBasisStateRepresentations_warnings
    ${ManybodyBasisStateRepresentations_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(ManybodyBasisStateRepresentations_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    ManybodyBasisStateRepresentations_configure_linker(ManybodyBasisStateRepresentations_options)
  endif()

  include(cmake/Sanitizers.cmake)
  ManybodyBasisStateRepresentations_enable_sanitizers(
    ManybodyBasisStateRepresentations_options
    ${ManybodyBasisStateRepresentations_ENABLE_SANITIZER_ADDRESS}
    ${ManybodyBasisStateRepresentations_ENABLE_SANITIZER_LEAK}
    ${ManybodyBasisStateRepresentations_ENABLE_SANITIZER_UNDEFINED}
    ${ManybodyBasisStateRepresentations_ENABLE_SANITIZER_THREAD}
    ${ManybodyBasisStateRepresentations_ENABLE_SANITIZER_MEMORY})

  set_target_properties(ManybodyBasisStateRepresentations_options PROPERTIES UNITY_BUILD ${ManybodyBasisStateRepresentations_ENABLE_UNITY_BUILD})

  if(ManybodyBasisStateRepresentations_ENABLE_PCH)
    target_precompile_headers(
      ManybodyBasisStateRepresentations_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(ManybodyBasisStateRepresentations_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    ManybodyBasisStateRepresentations_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(ManybodyBasisStateRepresentations_ENABLE_CLANG_TIDY)
    ManybodyBasisStateRepresentations_enable_clang_tidy(ManybodyBasisStateRepresentations_options ${ManybodyBasisStateRepresentations_WARNINGS_AS_ERRORS})
  endif()

  if(ManybodyBasisStateRepresentations_ENABLE_CPPCHECK)
    ManybodyBasisStateRepresentations_enable_cppcheck(${ManybodyBasisStateRepresentations_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(ManybodyBasisStateRepresentations_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    ManybodyBasisStateRepresentations_enable_coverage(ManybodyBasisStateRepresentations_options)
  endif()

  if(ManybodyBasisStateRepresentations_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(ManybodyBasisStateRepresentations_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(ManybodyBasisStateRepresentations_ENABLE_HARDENING AND NOT ManybodyBasisStateRepresentations_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_UNDEFINED
       OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_ADDRESS
       OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_THREAD
       OR ManybodyBasisStateRepresentations_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    ManybodyBasisStateRepresentations_enable_hardening(ManybodyBasisStateRepresentations_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
