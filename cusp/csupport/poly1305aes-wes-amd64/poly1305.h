#ifndef POLY1305_AMD64_H
#define POLY1305_AMD64_H

extern void poly1305_amd64(unsigned char out[16],
  const unsigned char r[16],
  const unsigned char s[16],
  const unsigned char m[],unsigned int l);

#ifndef poly1305_implementation
#define poly1305_implementation "poly1305_amd64"
#define poly1305 poly1305_amd64
#endif

#endif
