#!/bin/bash

gcc api-example.c -I compat/jansson -o ../cgminer-api
gcc cgminer-api-my.c -I compat/jansson -o ../cgminer-api-my