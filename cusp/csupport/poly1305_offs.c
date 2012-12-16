#if (defined(__x86_64__))
#include "poly1305aes-wes-amd64/poly1305.h"
#elif (defined(__i386__))
#include "poly1305aes-20050218/poly1305_ppro.h"
#else
#error No assembler available
#endif

void poly1305_offs(
  unsigned char *dest,
  unsigned char *key,
  unsigned char *nonce,
  unsigned char *text, int text_offset, int text_length)
{
  poly1305(dest, key, nonce, text+text_offset, text_length);
}
