#!/bin/sh
eval $(go env); make GOROOT=${GOROOT} GOOS=${GOOS} GOARCH=${GOARCH}
