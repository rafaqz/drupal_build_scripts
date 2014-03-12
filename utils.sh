#!/bin/bash

run() {
  if pushd "${2}" > /dev/null; then
    if ! eval ${1}; then
      die "Command ${1} failed in directory ${2}!";
    fi
    popd > /dev/null
  else
    die "Tried to run ${1} in ${2} but ${2} does not exist!";
  fi
}

dep() {
  # Print function names
  printf "**** Dep: \"$1\" ^ Called from function: \"${FUNCNAME[ 1 ]}\"" | column -c 2 -t -s "^"
  if ! exists $1 in completed_funcs; then
    printf ">>>> Run: \"$1\" ^ Called from function: \"${FUNCNAME[ 1 ]}\"" | column -c 2 -t -s "^"
    $1
    completed_funcs[$1]=TRUE;
    printf ">>>> Success: \"$1\"\n"
  fi
}

call() {
  printf ">>>> Run: \"$1\" ^ Called from function: \"${FUNCNAME[ 1 ]}\"" | column -c 2 -t -s "^"
  $1
  printf ">>>> Success: \"$1\"\n"
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
  printf ">>>> Error: ${1} in function: ${FUNCNAME[ 1 ]} < ${FUNCNAME[ 2 ]} < ${FUNCNAME[ 3 ]} < ${FUNCNAME[ 4 ]} \n\a"
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
  echo "${1}"
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
  run "find ${1} -type d -exec chmod ${2} '{}' \;"
}

set_file_permissions() {
  printf "Changing permissions of all files inside \"${1}\" to \"${2}\"...\n"
  run "find ${1} -type f -exec chmod ${2} '{}' \;"
}
