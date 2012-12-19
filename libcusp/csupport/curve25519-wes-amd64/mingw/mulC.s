.text
.p2align 5
.globl _field25519_wes_mulC
.globl field25519_wes_mulC
_field25519_wes_mulC:
field25519_wes_mulC:
mov  %r8,%r8
mov  %rdx,%r9
mov  $0x7ffffffffffff,%r10
movq   0(%r9),%rax
imul %r8
shld $13,%rax,%rdx
and  %r10,%rax
mov  %rdx,%r11
movd   %rax,%xmm0
movq   8(%r9),%rax
imul %r8
shld $13,%rax,%rdx
and  %r10,%rax
add  %r11,%rax
mov  %rdx,%r11
movq   %rax,8(%rcx)
movq   16(%r9),%rax
imul %r8
shld $13,%rax,%rdx
and  %r10,%rax
add  %r11,%rax
mov  %rdx,%r11
movq   %rax,16(%rcx)
movq   24(%r9),%rax
imul %r8
shld $13,%rax,%rdx
and  %r10,%rax
add  %r11,%rax
mov  %rdx,%r11
movq   %rax,24(%rcx)
movq   32(%r9),%rax
imul %r8
shld $13,%rax,%rdx
and  %r10,%rax
add  %r11,%rax
mov  %rdx,%rdx
movq   %rax,32(%rcx)
movd   %xmm0,%r8
imul  $19,%rdx
add  %rdx,%r8
movq   %r8,0(%rcx)
ret
