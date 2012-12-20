# GoCUSP
GoCUSP is a **work-in-progress** wrapper for libcusp, the initial implementation of the [Channel-based Unidirectional Stream Protoco (CUSP)](http://www.dvs.tu-darmstadt.de/research/cusp/). GoCUSP is wrapped using SWIG.

## Install
GoCUSP relies on a Makefile build system, so the installation is different from a vanilla Go package:

```
go get -u -d github.com/liamzebedee/gocusp
eval $(go env); cd ${GOROOT}/src/pkg/github.com/liamzebedee/gocusp; make GOROOT=${GOROOT} GOOS=${GOOS} GOARCH=${GOARCH}
```

## Usage
```
import "github.com/liamzebedee/gocusp/cusp"
```

## Licensing
GoCUSP is licensed under GPLv3 to Liam (liamzebedee) Edwards-Playne. 

## Notes
```cusp``` contains the GoCUSP wrapper, ```libcusp``` contains the original CUSP library.
