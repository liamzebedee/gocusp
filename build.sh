#!/bin/sh
eval $(go env); make GOROOT=${GOROOT} GOOS=${GOOS} GOARCH=${GOARCH}
LD_LIBRARY_PATH=/usr/local/lib; export LD_LIBRARY_PATH
go test ./examples
