.text
.p2align 5
.globl _field25519_wes_sub
.globl field25519_wes_sub
_field25519_wes_sub:
field25519_wes_sub:
movq   0(%rsi),%rcx
movq   8(%rsi),%r8
movq   16(%rsi),%r9
movq   24(%rsi),%rax
movq   32(%rsi),%rsi
subq 0(%rdx),%rcx
subq 8(%rdx),%r8
subq 16(%rdx),%r9
subq 24(%rdx),%rax
subq 32(%rdx),%rsi
movq   %rcx,0(%rdi)
movq   %r8,8(%rdi)
movq   %r9,16(%rdi)
movq   %rax,24(%rdi)
movq   %rsi,32(%rdi)
ret
