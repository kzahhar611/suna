#!/bin/bash

port=$1

check_port() {
    nc -z localhost $port &>/dev/null
    echo $?
}

result=$(check_port)
echo "Port $port availability status: $result (0 means port is in use, 1 means port is available)"
