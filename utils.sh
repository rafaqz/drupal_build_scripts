#!/bin/bash

declare -A completed_deps

run_cmd() {
  debug "Run" "$1" ${FUNCNAME[ 1 ]}
  if ! eval $1; then
    die "Command "$1" failed!";
  fi
}

dep() {
  # Respects dependencies.
  debug "Dep" $1 ${FUNCNAME[ 1 ]}
  if ! exists $1 in completed_deps; then
    debug "Call" $1 ${FUNCNAME[ 1 ]}
    $1
    completed_deps[$1]=TRUE;
    debug "Success" $1 ${FUNCNAME[ 1 ]}
  fi
}

reset() {
  # Allways runs but sets completed deps.
  debug "Reset" $1 ${FUNCNAME[ 1 ]}
  $1
  completed_deps[$1]=TRUE;
  debug "Success" $1 ${FUNCNAME[ 1 ]}
}

call() {
  # Ignores dependencies .
  debug "Call" $1 ${FUNCNAME[ 1 ]}
  $1
  debug "Success" $1 ${FUNCNAME[ 1 ]}
}

debug() {
  #if [ "$OUTPUT" == "$DEBUG" ] ; then
    # Print arguments and function parent in columns
    printf "%-50s %s\n" ">>> $1: \"$2\""  "Called from: \"$3\""
  #fi
}

message() {
  if [ "$QUIET" != "y" ] ; then
    echo "$1"
  fi
}

exists() {
  if [ "$2" != in ]; then
    printf "Incorrect usage of \"exists()\"\n"
    echo "Correct usage: exists {key} in {array}"
    return
  fi   
  eval '[ ${'$3'[$1]+Completed} ]'  
}

die() {
  printf ">>> Error: ${1} in function: ${FUNCNAME[ 1 ]} < ${FUNCNAME[ 2 ]} < ${FUNCNAME[ 3 ]} < ${FUNCNAME[ 4 ]} \n\a"
  exit 1
}

check_dir() {
  if [[ -z "$1" ]]; then
    die "directory variable is empty"
  fi
  if [ ! -d $1 ]; then
    # Handle missing install dir. 
    die "$1 directory dosn't exist"
  fi
}

confirm() {
  if [ "$CONFIRMATION" == "y" ]; then
    return
  fi
  # Check if this is for reals.
  while true; do
    read -p "Please confirm (yes or no) y/n " yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no. ";;
    esac
  done
}

set_dir_permissions() {
  printf "Changing permissions of all directories inside \"${1}\" to \"${2}\"...\n"
  find ${1} -type d -exec chmod ${2} '{}' \;
}

set_file_permissions() {
  printf "Changing permissions of all files inside \"${1}\" to \"${2}\"...\n"
  find ${1} -type f -exec chmod ${2} '{}' \;
}
