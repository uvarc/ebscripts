#!/bin/bash -e
# for scrontab
git checkout main && ./sync p
git checkout derp && ./sync d
