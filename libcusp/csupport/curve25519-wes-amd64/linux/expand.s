.text
.p2align 5
.globl _field25519_wes_expand
.globl field25519_wes_expand
_field25519_wes_expand:
field25519_wes_expand:
mov  $0x7ffffffffffff,%rdx
movq   0(%rsi),%rcx
movq   6(%rsi),%r8
movq   12(%rsi),%r9
movq   19(%rsi),%rax
movq   25(%rsi),%rsi
shr  $3,%r8
shr  $6,%r9
shr  $1,%rax
shr  $4,%rsi
and  %rdx,%rcx
and  %rdx,%r8
and  %rdx,%r9
and  %rdx,%rax
and  %rdx,%rsi
movq   %rcx,0(%rdi)
movq   %r8,8(%rdi)
movq   %r9,16(%rdi)
movq   %rax,24(%rdi)
movq   %rsi,32(%rdi)
ret
