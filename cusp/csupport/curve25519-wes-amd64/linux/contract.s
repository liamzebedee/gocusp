.text
.p2align 5
.globl _field25519_wes_contract
.globl field25519_wes_contract
_field25519_wes_contract:
field25519_wes_contract:
movd   %rdi,%xmm0
movq   0(%rsi),%rdi
movq   8(%rsi),%rdx
movq   16(%rsi),%rcx
movq   24(%rsi),%r8
movq   32(%rsi),%rsi
mov  %rdi,%r9
sar  $63,%r9
mov  %rdx,%rax
shl  $51,%rax
sar  $13,%rdx
add  %rax,%rdi
adc %r9,%rdx
mov  %rdx,%r9
sar  $63,%r9
mov  %rcx,%rax
shl  $38,%rax
sar  $26,%rcx
add  %rax,%rdx
adc %r9,%rcx
mov  %rcx,%r9
sar  $63,%r9
mov  %r8,%rax
shl  $25,%rax
sar  $39,%r8
add  %rax,%rcx
adc %r9,%r8
mov  %r8,%r9
sar  $63,%r9
mov  %rsi,%rax
shl  $12,%rax
sar  $52,%rsi
add  %rax,%r8
adc %r9,%rsi
shld $1,%r8,%rsi
shl  $1,%r8
shr  $1,%r8
mov  %rsi,%r9
sar  $63,%r9
lea  1(%rsi,%r9),%rsi
imul  $19,%rsi
add  %rsi,%rdi
adc %r9,%rdx
adc %r9,%rcx
adc %r9,%r8
shl  $63,%r9
add  %r9,%r8
mov  $19,%rsi
mov  %r8,%r9
sar  $63,%r9
not  %r9
and  %r9,%rsi
sub  %rsi,%rdi
sbb $0,%rdx
sbb $0,%rcx
sbb $0,%r8
shl  $1,%r8
shr  $1,%r8
movd   %xmm0,%rsi
movq   %rdi,0(%rsi)
movq   %rdx,8(%rsi)
movq   %rcx,16(%rsi)
movq   %r8,24(%rsi)
ret
