#!/bin/bash

echo "Zipping lambdas..."

if command -v zip >/dev/null 2>&1; then
  echo "Using zip..."

  cd lambda/producer && zip -r ../../producer.zip . && cd -
  cd lambda/consumer && zip -r ../../consumer.zip . && cd -
  cd lambda/status && zip -r ../../status.zip . && cd -

else
  echo "zip not found, using PowerShell..."

  powershell Compress-Archive -Path lambda/producer/* -DestinationPath producer.zip -Force
  powershell Compress-Archive -Path lambda/consumer/* -DestinationPath consumer.zip -Force
  powershell Compress-Archive -Path lambda/status/* -DestinationPath status.zip -Force
fi

echo "Done"