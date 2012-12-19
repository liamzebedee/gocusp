.text
.p2align 5
.globl _field25519_wes_add
.globl field25519_wes_add
_field25519_wes_add:
field25519_wes_add:
movq   0(%rsi),%rcx
movq   8(%rsi),%r8
movq   16(%rsi),%r9
movq   24(%rsi),%rax
movq   32(%rsi),%rsi
addq 0(%rdx),%rcx
addq 8(%rdx),%r8
addq 16(%rdx),%r9
addq 24(%rdx),%rax
addq 32(%rdx),%rsi
movq   %rcx,0(%rdi)
movq   %r8,8(%rdi)
movq   %r9,16(%rdi)
movq   %rax,24(%rdi)
movq   %rsi,32(%rdi)
ret
