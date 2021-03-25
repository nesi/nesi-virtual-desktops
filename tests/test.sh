#!/bin/bash -e


# Test 1, local ephemeral.
../vdt start 11111
# Test 2, local persistant.
../vdt -p start 11112
# Test 3, remote ephemeral.
salloc ../vdt start 11113
# Test 4, remote persistant.
salloc nohup ../vdt start 11114