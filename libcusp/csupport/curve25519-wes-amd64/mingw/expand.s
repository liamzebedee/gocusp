.text
.p2align 5
.globl _field25519_wes_expand
.globl field25519_wes_expand
_field25519_wes_expand:
field25519_wes_expand:
mov  $0x7ffffffffffff,%r8
movq   0(%rdx),%r9
movq   6(%rdx),%rax
movq   12(%rdx),%r10
movq   19(%rdx),%r11
movq   25(%rdx),%rdx
shr  $3,%rax
shr  $6,%r10
shr  $1,%r11
shr  $4,%rdx
and  %r8,%r9
and  %r8,%rax
and  %r8,%r10
and  %r8,%r11
and  %r8,%rdx
movq   %r9,0(%rcx)
movq   %rax,8(%rcx)
movq   %r10,16(%rcx)
movq   %r11,24(%rcx)
movq   %rdx,32(%rcx)
ret
