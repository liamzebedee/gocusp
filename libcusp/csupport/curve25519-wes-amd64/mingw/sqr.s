.text
.p2align 5
.globl _field25519_wes_sqr
.globl field25519_wes_sqr
_field25519_wes_sqr:
field25519_wes_sqr:
mov %rsp,%r11
and $31,%r11
add $64,%r11
sub %r11,%rsp
movq %r11,0(%rsp)
movq %r12,8(%rsp)
movq %r13,16(%rsp)
movq %r14,24(%rsp)
movq %r15,32(%rsp)
movq %rdi,40(%rsp)
movq %rsi,48(%rsp)
movd   %rcx,%xmm0
movq   0(%rdx),%rcx
movq   8(%rdx),%r8
movq   16(%rdx),%r9
movq   24(%rdx),%r10
movq   32(%rdx),%r11
mov  %r11,%r12
mov  %r10,%r13
imul  $19,%r12
imul  $19,%r13
lea  (%r8,%r8),%rax
imul %r12
mov  %rax,%r14
mov  %rdx,%r15
lea  (%r9,%r9),%rax
imul %r13
add  %rax,%r14
adc %rdx,%r15
mov  %rcx,%rax
imul %rcx
add  %rax,%r14
adc %rdx,%r15
mov  %r14,%rdi
shrd $51,%r15,%r14
sar  $51,%r15
lea  (%r9,%r9),%rax
imul %r12
add  %rax,%r14
adc %rdx,%r15
mov  %r10,%rax
imul %r13
add  %rax,%r14
adc %rdx,%r15
lea  (%rcx,%rcx),%rax
imul %r8
add  %rax,%r14
adc %rdx,%r15
mov  %r14,%r13
shrd $51,%r15,%r14
sar  $51,%r15
lea  (%r10,%r10),%rax
imul %r12
add  %rax,%r14
adc %rdx,%r15
lea  (%rcx,%rcx),%rax
imul %r9
add  %rax,%r14
adc %rdx,%r15
mov  %r8,%rax
imul %r8
add  %rax,%r14
adc %rdx,%r15
mov  %r14,%rsi
shrd $51,%r15,%r14
sar  $51,%r15
mov  %r11,%rax
imul %r12
add  %rax,%r14
adc %rdx,%r15
lea  (%rcx,%rcx),%rax
imul %r10
add  %rax,%r14
adc %rdx,%r15
lea  (%r8,%r8),%rax
imul %r9
add  %rax,%r14
adc %rdx,%r15
mov  %r14,%r12
shrd $51,%r15,%r14
sar  $51,%r15
lea  (%rcx,%rcx),%rax
imul %r11
add  %rax,%r14
adc %rdx,%r15
lea  (%r8,%r8),%rax
imul %r10
add  %rax,%r14
adc %rdx,%r15
mov  %r9,%rax
imul %r9
add  %rax,%r14
adc %rdx,%r15
mov  %r14,%rcx
shrd $51,%r15,%r14
sar  $51,%r15
mov  $0x7ffffffffffff,%r8
movd   %xmm0,%r9
and  %r8,%rdi
and  %r8,%r13
and  %r8,%rsi
and  %r8,%r12
and  %r8,%rcx
imul  $19,%r15
mov  $19,%rax
mul  %r14
add  %r15,%rdx
and  %rax,%r8
shrd $51,%rdx,%rax
add  %r8,%rdi
add  %rax,%r13
movq   %rdi,0(%r9)
movq   %r13,8(%r9)
movq   %rsi,16(%r9)
movq   %r12,24(%r9)
movq   %rcx,32(%r9)
movq 0(%rsp),%r11
movq 8(%rsp),%r12
movq 16(%rsp),%r13
movq 24(%rsp),%r14
movq 32(%rsp),%r15
movq 40(%rsp),%rdi
movq 48(%rsp),%rsi
add %r11,%rsp
ret
