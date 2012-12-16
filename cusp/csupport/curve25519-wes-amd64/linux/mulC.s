.text
.p2align 5
.globl _field25519_wes_mulC
.globl field25519_wes_mulC
_field25519_wes_mulC:
field25519_wes_mulC:
mov  %rdx,%rcx
mov  %rsi,%rsi
mov  $0x7ffffffffffff,%r8
movq   0(%rsi),%rax
imul %rcx
shld $13,%rax,%rdx
and  %r8,%rax
mov  %rdx,%r9
movd   %rax,%xmm0
movq   8(%rsi),%rax
imul %rcx
shld $13,%rax,%rdx
and  %r8,%rax
add  %r9,%rax
mov  %rdx,%r9
movq   %rax,8(%rdi)
movq   16(%rsi),%rax
imul %rcx
shld $13,%rax,%rdx
and  %r8,%rax
add  %r9,%rax
mov  %rdx,%r9
movq   %rax,16(%rdi)
movq   24(%rsi),%rax
imul %rcx
shld $13,%rax,%rdx
and  %r8,%rax
add  %r9,%rax
mov  %rdx,%r9
movq   %rax,24(%rdi)
movq   32(%rsi),%rax
imul %rcx
shld $13,%rax,%rdx
and  %r8,%rax
add  %r9,%rax
mov  %rdx,%rsi
movq   %rax,32(%rdi)
movd   %xmm0,%rdx
imul  $19,%rsi
add  %rsi,%rdx
movq   %rdx,0(%rdi)
ret
