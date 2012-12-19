.text
.p2align 5
.globl _field25519_wes_sub
.globl field25519_wes_sub
_field25519_wes_sub:
field25519_wes_sub:
movq   0(%rdx),%r9
movq   8(%rdx),%rax
movq   16(%rdx),%r10
movq   24(%rdx),%r11
movq   32(%rdx),%rdx
subq 0(%r8),%r9
subq 8(%r8),%rax
subq 16(%r8),%r10
subq 24(%r8),%r11
subq 32(%r8),%rdx
movq   %r9,0(%rcx)
movq   %rax,8(%rcx)
movq   %r10,16(%rcx)
movq   %r11,24(%rcx)
movq   %rdx,32(%rcx)
ret
