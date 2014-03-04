#!/bin/bash

v="v3.0"
lens=${#v}
test=${v#"v"}
printf "\n%s (%s)\n", $test $lens

