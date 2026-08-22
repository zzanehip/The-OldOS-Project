#include "MCHash.h"

unsigned int mailcore::hashCompute(const char * key, unsigned int len) {
  unsigned int c = 5381;
  const char * k = key;
  
  while (len--) {
    c = ((c << 5) + c) + *k++;
  }
  
  return c;
}
