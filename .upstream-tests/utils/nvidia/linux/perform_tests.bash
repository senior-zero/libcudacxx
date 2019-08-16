#! /bin/bash

function usage {
  echo "Usage: $0 [flags...] <tests...>|all"
  echo 
  echo "Run <tests> from the libc++ and libcu++ test suites."
  echo "If no tests or \"all\" is specified, all tests are run."
  echo
  echo "-h, -help, --help                : Print this message."
  echo "--dry-run                        : Show what commands would be invoked;"
  echo "                                 : don't actually execute anything."
  echo "--skip-base-tests-build          : Do not build (or run) any tests."
  echo "                                 : Overrides \${LIBCUDACXX_SKIP_BASE_TESTS_BUILD}."
  echo "--skip-tests-runs                : Build tests but do not run them."
  echo "                                 : Overrides \${LIBCUDACXX_SKIP_TESTS_RUN}."
  echo "--skip-libcxx-tests              : Do not build (or run) any libc++ tests."
  echo "                                 : Overrides \${LIBCUDACXX_SKIP_LIBCXX_TESTS}."
  echo "--skip-libcudacxx-tests          : Do not build (or run) any libcu++ tests."
  echo "                                 : Overrides \${LIBCUDACXX_SKIP_LIBCUDACXX_TESTS}."
  echo "--skip-arch-detection            : Do not automatically detect the SM architecture"
  echo "                                 : for tests runs."
  echo "                                 : Overrides \${LIBCUDACXX_SKIP_ARCH_DETECTION}."
  echo
  echo "--libcxx-lit-site-config <file>     : Use <file> as the libc++ lit site config"
  echo "                                    : (default: \${LIBCUDACXX_PATH}/build/libcxx/test/lit.site.cfg)."
  echo "--libcudacxx-lit-site-config <file> : Use <file> as the libcu++ lit site config"
  echo "                                    : (default: \${LIBCUDACXX_PATH}/libcxx/build/test/lit.site.cfg)."
  echo "--libcxx-log-file <file>            : Log libc++ test results to <file> in"
  echo "                                    : addition to stdout (default: libcxx_lit.log)."
  echo "--libcudacxx-log-file <file>        : Log libcu++ test results to <file> in"
  echo "                                    : addition to stdout (default: libcudacxx_lit.log)."
  echo
  echo "\${LIBCUDACXX_SKIP_BASE_TESTS_BUILD}   : If set and non-zero, do not build"
  echo "                                      : (or run) any tests."
  echo "\${LIBCUDACXX_SKIP_TESTS_RUN}          : If set and non-zero, build tests"
  echo "                                      : but do not run them."
  echo "\${LIBCUDACXX_SKIP_LIBCXX_TESTS}       : If set and non-zero, do not build"
  echo "                                      : (or run) any libc++ tests."
  echo "\${LIBCUDACXX_SKIP_LIBCUDACXX_TESTS}   : If set and non-zero, do not build"
  echo "                                      : (or run) any libcu++ tests."
  echo "\${LIBCUDACXX_SKIP_ARCH_DETECTION}     : If set, non-zero, and"
  echo "                                      : \${LIBCUDACXX_COMPUTE_ARCHS} is unset,"
  echo "                                      : do not automatically detect the SM"
  echo "                                      : architecture."
  echo "\${LIBCUDACXX_COMPUTE_ARCHS}           : A space-separated list of SM"
  echo "                                      : architectures (specified as integers)"
  echo "                                      : to target. If empty, either the"
  echo "                                      : architecture is automatically"
  echo "                                      : detected (for tests runs if detection"
  echo "                                      : isn't disabled) or all known SM"
  echo "                                      : architectures are targeted."

  exit 1
}

SCRIPT_PATH=$(cd $(dirname ${0}); pwd -P)

LIBCUDACXX_PATH=$(realpath ${SCRIPT_PATH}/../../../../)

###############################################################################
# Command Line Processing.

LIT_PREFIX="time"

LIBCXX_LIT_SITE_CONFIG=${LIBCUDACXX_PATH}/libcxx/build/test/lit.site.cfg
LIBCUDACXX_LIT_SITE_CONFIG=${LIBCUDACXX_PATH}/build/libcxx/test/lit.site.cfg

LIBCXX_LOG_FILE=libcxx_lit.log
LIBCUDACXX_LOG_FILE=libcudacxx_lit.log

RAW_TEST_TARGETS=""

while test ${#} != 0
do
  case "${1}" in
  -h) usage ;;
  -help) usage ;;
  --help) usage ;;
  --dry-run) LIT_PREFIX="echo" ;;
  --libcxx-lit-site-config)
    shift # The next argument is the directory.
    LIBCXX_LIT_SITE_CONFIG=${1}
    ;;
  --libcudacxx-lit-site-config)
    shift # The next argument is the directory.
    LIBCUDACXX_LIT_SITE_CONFIG=${1}
    ;;
  --skip-base-tests-build)    LIBCUDACXX_SKIP_BASE_TESTS_BUILD=1 ;;
  --skip-tests-runs)          LIBCUDACXX_SKIP_TESTS_RUN=1 ;;
  --skip-libcxx-tests)        LIBCUDACXX_SKIP_LIBCXX_TESTS=1 ;;
  --skip-libcudacxx-tests)    LIBCUDACXX_SKIP_LIBCUDACXX_TESTS=1 ;;
  --skip-arch-detection)      LIBCUDACXX_SKIP_ARCH_DETECTION=1 ;;
  --libcxx-log-file)
    shift # The next argument is the file.
    LIBCXX_LOG_FILE=${1}
    ;;
  --libcudacxx-log-file)
    shift # The next argument is the file.
    LIBCUDACXX_LOG_FILE=${1}
    ;;
  *)
    RAW_TEST_TARGETS="${RAW_TEST_TARGETS:+${RAW_TEST_TARGETS} }${1}"
    ;;
  esac
  shift
done

if [ -e "${LIBCXX_LOG_FILE}" ]
then
  rm ${LIBCXX_LOG_FILE}
fi

if [ -e "${LIBCUDACXX_LOG_FILE}" ]
then
  rm ${LIBCUDACXX_LOG_FILE}
fi

LIBCXX_TEST_TARGETS="libcxx/test"
LIBCUDACXX_TEST_TARGETS="test"

if [ "${RAW_TEST_TARGETS:-all}" != "all" ]
then
  LIBCXX_TEST_TARGETS=""
  LIBCUDACXX_TEST_TARGETS=""
  for test in ${RAW_TEST_TARGETS}
  do
    LIBCXX_TEST_TARGETS="${LIBCXX_TEST_TARGETS:+${LIBCXX_TEST_TARGETS} }${LIBCUDACXX_PATH}/libcxx/test/${test}"
    LIBCUDACXX_TEST_TARGETS="${LIBCUDACXX_TEST_TARGETS:+${LIBCUDACXX_TEST_TARGETS} }${LIBCUDACXX_PATH}/test/${test}"
  done
fi

###############################################################################
# SM Architecture Detection
  
if [ "${LIBCUDACXX_SKIP_ARCH_DETECTION:-0}" == "0" ] && \
   [ "${LIBCUDACXX_SKIP_TESTS_RUN:-0}" == "0" ] && \
   [ ! -n "${LIBCUDACXX_COMPUTE_ARCHS}" ] 
then
  # Use the libcu++ log file as scratch space for the detection test.
  LIBCXX_SITE_CONFIG=${LIBCUDACXX_LIT_SITE_CONFIG} \
  bash -c "lit -vv -a ${LIBCUDACXX_PATH}/test/nothing_to_do.pass.cpp" \
  2>&1 | tee ${LIBCUDACXX_LOG_FILE}
  if [ "${PIPESTATUS[0]}" != "0" ]; then exit 1; fi

  DEVICE_0_COMPUTE_ARCH=$(egrep '^Device 0:' ${LIBCUDACXX_LOG_FILE} | sed 's/^Device 0: ".*", Selected, SM\([0-9]\+\), [0-9]\+ \[bytes\]/\1/')

  # Clear out the libcu++ log file now that we are done with it.
  if [ -e "${LIBCUDACXX_LOG_FILE}" ]
  then
    rm ${LIBCUDACXX_LOG_FILE}
  fi

  echo "# DETECTION SM Architecture : Device 0, ${DEVICE_0_COMPUTE_ARCH}"

  if (( 35 <= ${DEVICE_0_COMPUTE_ARCH:-0} ))
  then
    LIBCUDACXX_COMPUTE_ARCHS=${DEVICE_0_COMPUTE_ARCH}
  fi
fi

###############################################################################
# Environment Variable Processing

if [ "${LIBCUDACXX_SKIP_BASE_TESTS_BUILD:-0}" != "0" ]
then
  exit 0
fi

LIT_FLAGS="-vv -a"
if [ "${LIBCUDACXX_SKIP_TESTS_RUN:-0}" != "0" ]
then
  LIT_FLAGS="${LIT_FLAGS:+${LIT_FLAGS} }-Dexecutor=\"NoopExecutor()\""
fi

if [ -n "${LIBCUDACXX_COMPUTE_ARCHS}" ]
then
  LIT_COMPUTE_ARCHS_FLAG="-Dcompute_archs=\""
  LIT_COMPUTE_ARCHS_SUFFIX="\""
fi

###############################################################################

if [ "${LIBCUDACXX_SKIP_LIBCXX_TESTS:-0}" == "0" ]
then
  TIMEFORMAT="# WALLTIME libc++ : %R [sec]" \
  LIBCXX_SITE_CONFIG=${LIBCXX_LIT_SITE_CONFIG} \
  bash -c "${LIT_PREFIX} lit ${LIT_FLAGS} ${LIBCXX_TEST_TARGETS}" \
  2>&1 | tee ${LIBCXX_LOG_FILE}
  if [ "${PIPESTATUS[0]}" != "0" ]; then exit 1; fi
fi

if [ "${LIBCUDACXX_SKIP_LIBCUDACXX_TESTS:-0}" == "0" ]
then
  TIMEFORMAT="# WALLTIME libcu++: %R [sec]" \
  LIBCXX_SITE_CONFIG=${LIBCUDACXX_LIT_SITE_CONFIG} \
  bash -c "${LIT_PREFIX} lit ${LIT_FLAGS} ${LIT_COMPUTE_ARCHS_FLAG}${LIBCUDACXX_COMPUTE_ARCHS}${LIT_COMPUTE_ARCHS_SUFFIX} ${LIBCUDACXX_TEST_TARGETS}" \
  2>&1 | tee ${LIBCUDACXX_LOG_FILE}
  if [ "${PIPESTATUS[0]}" != "0" ]; then exit 1; fi
fi

###############################################################################

# If any of the lines searched for below aren't present in the log files, the
# grep commands will return nothing, and the variables will be empty. Bash
# treats empty variables as zero for the purposes of arithmetic, which is what
# we want anyways, so we don't need to do anything else.

if [ -e "${LIBCXX_LOG_FILE}" ]
then
  LIBCXX_EXPECTED_PASSES=$(    egrep 'Expected Passes'     ${LIBCXX_LOG_FILE} | sed 's/^  Expected Passes    : \([0-9]\+\)/\1/')
  LIBCXX_EXPECTED_FAILURES=$(  egrep 'Expected Failures'   ${LIBCXX_LOG_FILE} | sed 's/^  Expected Failures  : \([0-9]\+\)/\1/')
  LIBCXX_UNSUPPORTED_TESTS=$(  egrep 'Unsupported Tests'   ${LIBCXX_LOG_FILE} | sed 's/^  Unsupported Tests  : \([0-9]\+\)/\1/')
  LIBCXX_UNEXPECTED_PASSES=$(  egrep 'Unexpected Passes'   ${LIBCXX_LOG_FILE} | sed 's/^  Unexpected Passes  : \([0-9]\+\)/\1/')
  LIBCXX_UNEXPECTED_FAILURES=$(egrep 'Unexpected Failures' ${LIBCXX_LOG_FILE} | sed 's/^  Unexpected Failures: \([0-9]\+\)/\1/')
fi

if [ -e "${LIBCUDACXX_LOG_FILE}" ]
then
  LIBCUDACXX_EXPECTED_PASSES=$(    egrep 'Expected Passes'     ${LIBCUDACXX_LOG_FILE} | sed 's/^  Expected Passes    : \([0-9]\+\)/\1/')
  LIBCUDACXX_EXPECTED_FAILURES=$(  egrep 'Expected Failures'   ${LIBCUDACXX_LOG_FILE} | sed 's/^  Expected Failures  : \([0-9]\+\)/\1/')
  LIBCUDACXX_UNSUPPORTED_TESTS=$(  egrep 'Unsupported Tests'   ${LIBCUDACXX_LOG_FILE} | sed 's/^  Unsupported Tests  : \([0-9]\+\)/\1/')
  LIBCUDACXX_UNEXPECTED_PASSES=$(  egrep 'Unexpected Passes'   ${LIBCUDACXX_LOG_FILE} | sed 's/^  Unexpected Passes  : \([0-9]\+\)/\1/')
  LIBCUDACXX_UNEXPECTED_FAILURES=$(egrep 'Unexpected Failures' ${LIBCUDACXX_LOG_FILE} | sed 's/^  Unexpected Failures: \([0-9]\+\)/\1/')
fi

LIBCXX_PASSES=$((  LIBCXX_EXPECTED_PASSES   + LIBCXX_EXPECTED_FAILURES))
LIBCXX_FAILURES=$((LIBCXX_UNEXPECTED_PASSES + LIBCXX_UNEXPECTED_FAILURES))
LIBCXX_TOTAL=$((   LIBCXX_PASSES            + LIBCXX_FAILURES))

LIBCUDACXX_PASSES=$((  LIBCUDACXX_EXPECTED_PASSES   + LIBCUDACXX_EXPECTED_FAILURES))
LIBCUDACXX_FAILURES=$((LIBCUDACXX_UNEXPECTED_PASSES + LIBCUDACXX_UNEXPECTED_FAILURES))
LIBCUDACXX_TOTAL=$((   LIBCUDACXX_PASSES            + LIBCUDACXX_FAILURES))

OVERALL_PASSES=$((  LIBCXX_PASSES   + LIBCUDACXX_PASSES))
OVERALL_FAILURES=$((LIBCXX_FAILURES + LIBCUDACXX_FAILURES))
OVERALL_TOTAL=$((   LIBCXX_TOTAL    + LIBCUDACXX_TOTAL))

if [ "${OVERALL_TOTAL:-0}" != "0" ]
then
  printf "Score: %.2f%%\n" "$((10000 * ${OVERALL_PASSES} / ${OVERALL_TOTAL}))e-2"
else
  echo "Score: 0.00%"
fi
