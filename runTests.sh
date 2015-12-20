#!/bin/bash
echo "cooking the executable"
cd src
make
cd ..
echo "cooking is over"
echo "Tests compilations" > analysis.out
date >> analysis.out
for file in ./tst/*
do
  echo "$file"
  echo "$file" >>analysis.out
  ./src/krokodil "$file" >> analysis.out
done
