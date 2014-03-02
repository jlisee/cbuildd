#! /bin/bash

# Exit on error
set -e

# Clean up initial files
function clean() {
    rm -f test-main main.o cbd cbd.test
}

function checkout() {
    echo "[Running: ./test-main]"
    testout=$(./test-main)

    if [ "$testout" != "Hello, world!" ]; then
        echo "Output Invalid got value '$testout'"
        exit 1
    else
        echo "  GOOD"
    fi
}

function disp() {
    echo
    echo $*
}

clean

# Run tests
disp "[Running tests]"
go test

# Build everything
disp "[Build and install]"
go install
go build cmds/cbdcc.go
go build cmds/cbd.go
mv cbdcc cbd $GOPATH/bin

# The compile the program
disp "[Local only test]"

export CBD_POTENTIAL_HOST=''

cbdcc gcc -c data/main.c -o main.o
cbdcc gcc main.o -o test-main
checkout # Test the output

# Clean up
clean

# Now lets do it again over the network
disp "[Direct worker test]"

cbd &
d_pid=$!
trap "kill -9 ${d_pid}" EXIT

export CBD_POTENTIAL_HOST="localhost"

cbdcc gcc -c data/main.c -o main.o
cbdcc gcc main.o -o test-main
checkout # Test the output

clean
kill -9 ${d_pid} &> /dev/null

# Now lets do again over with a server and a worker
disp "[Server & worker test]"

export CBD_POTENTIAL_HOST=''
export CBD_SERVER="localhost:15800"

cbd -address $CBD_SERVER -server &
a_pid=$!
trap "kill -9 ${a_pid}" EXIT

cbd -address ":15786" &
d_pid=$!
trap "kill -9 ${d_pid}" EXIT

sleep 1

cbdcc gcc -c data/main.c -o main.o
cbdcc gcc main.o -o test-main
checkout # Test the output

clean
