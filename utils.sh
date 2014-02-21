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

completed() {
  func=${FUNCNAME[ 1 ]}
  completed_funcs[$func]=TRUE;
  echo $func
}

dep() {
  if ! exists $1 in completed_funcs; then
    $1
    completed_funcs[$1]=TRUE;
  fi
  # Print function names
  echo "***** $3 $2 $1 "
}

exists() {
  if [ "$2" != in ]; then
    echo "Incorrect usage."
    echo "Correct usage: exists {key} in {array}"
    return
  fi   
  eval '[ ${'$3'[$1]+Completed} ]'  
}

die() {
  echo "${1}"
  exit 1
}

check_dir() {
  if [[ -z "$1" ]]; then
    die "directory variable is empty"
  fi
  if cd $1; then
    echo "Directory $1 exists"
  else
    # Handle missing install dir. 
    die "$1 directory dosn't exist"
  fi
}

confirm() {
  echo "${1}"
  # Check if this is for reals.
  while true; do
    read -p "Please confirm (yes or no) y/n" yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no. ";;
    esac
  done
}

replace() {
  run "sed -i 's|$1|$2|g' $3"  
}
  
