#!/bin/bash

echo "Tests compilations" > analysis.out
date >> analysis.out
for file in ./tst/*
do
  echo "$file" >>analysis.out
  ./src/krokodil "$file" >> analysis.out
done
