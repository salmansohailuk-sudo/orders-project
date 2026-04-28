#!/bin/bash

echo "Zipping lambdas..."

cd lambda/producer && zip -r ../../producer.zip . && cd -
cd lambda/consumer && zip -r ../../consumer.zip . && cd -
cd lambda/status && zip -r ../../status.zip . && cd -

echo "Done"