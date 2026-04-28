#!/bin/bash

if [ -n "$BUILD_NUMBER" ]; then
  echo "build-$BUILD_NUMBER"
else
  echo "manual-$(date +%s)"
fi