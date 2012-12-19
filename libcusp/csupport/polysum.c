#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "poly1305aes-20050218/aes.h"
#include "poly1305aes-20050218/poly1305aes.h"

unsigned char nonce[16];
unsigned char kr[32] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
unsigned char mac[16];
unsigned char* block;
int fd;

/* Essentially a profiling tool to compare vs. md5sum/cksum */
int main (int argc, char** argv) {
  void* tmp;
  off_t len, align;
  int i;
  
  if (argc != 2) {
    fprintf(stderr, "Syntax: %s <filename>\n", argv[0]);
    return 1;
  }
  
  if ((fd = open(argv[1], O_RDONLY)) == -1) {
    perror(argv[1]);
    return 1;
  }
  
  len = lseek(fd, 0, SEEK_END);
  align = (len + 4095) & ~0x8ffUL;
  if ((tmp = mmap(0, align, PROT_READ|PROT_WRITE, MAP_PRIVATE, fd, 0)) == MAP_FAILED) {
    perror("mmap");
    return 1;
  }
  block = (unsigned char*)tmp;
  
  memset(nonce, 0, sizeof(nonce));
  poly1305aes_clamp(kr);
  poly1305aes_authenticate(mac,kr,nonce,block,len);
  
  for (i = 0; i < 16; ++i)
    printf("%02x", mac[i]);
  printf("\n");
  return 0;
}
