namespace CUSP {
class Endpoint;
};

%module cusp
%{
  #include "../libcusp/cusp/cbindings/include/cusp.h"
%}

#include "../libcusp/cusp/cbindings/include/cusp.h"

// TODO cuspInit TO init()
