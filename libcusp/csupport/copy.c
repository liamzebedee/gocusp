#include <string.h>
#include <stdint.h>

void bs_copy(
  unsigned char* dest,
  int32_t dest_off,
  unsigned char* source,
  int32_t source_off,
  int32_t length) {
   memcpy(dest+dest_off, source+source_off, length);
}
