.text
.p2align 5
.globl _aes128_amd64_2_block
.globl aes128_amd64_2_block
_aes128_amd64_2_block:
aes128_amd64_2_block:
mov %rsp,%r11
lea aes128_amd64_2_constants(%rip),%r10
sub %r10,%r11
and $4095,%r11
add $96,%r11
sub %r11,%rsp
movq %rdx,0(%rsp)
movq %rdi,8(%rsp)
movq %r11,16(%rsp)
movq %r12,24(%rsp)
movq %r13,32(%rsp)
movq %r14,40(%rsp)
movq %r15,48(%rsp)
movq %rbx,56(%rsp)
movq %rbp,64(%rsp)
movl   0(%rdx),%edi
movl   4(%rdx),%r8d
movl   8(%rdx),%r9d
movl   12(%rdx),%r10d
movl   0(%rsi),%edx
movl   4(%rsi),%ecx
movl   8(%rsi),%eax
movl   12(%rsi),%ebx
lea  aes128_amd64_2_tablex(%rip),%r11
movq 0(%rsp),%r12
xor  %rdi,%rdx
xor  %r8,%rcx
xor  %r9,%rax
xor  %r10,%rbx
movl   16(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%r13d
movzbl  %dh,%edi
shr  $16,%edx
movzbl  %dl,%r14d
movzbl  %dh,%ebp
movl   3(%r11,%r13,8),%edx
xor  %rsi,%rdx
movzbl  %cl,%r13d
movzbl  %ch,%esi
xorl 2(%r11,%rsi,8),%edx
shr  $16,%ecx
movzbl  %cl,%r15d
movzbl  %ch,%esi
movl   4(%r11,%rbp,8),%ecx
xorl 3(%r11,%r13,8),%ecx
movzbl  %al,%r13d
movzbl  %ah,%ebp
xorl 2(%r11,%rbp,8),%ecx
shr  $16,%eax
movzbl  %al,%ebp
xorl 1(%r11,%rbp,8),%edx
movzbl  %ah,%ebp
movl   1(%r11,%r14,8),%eax
xorl 4(%r11,%rsi,8),%eax
xorl 3(%r11,%r13,8),%eax
movzbl  %bl,%r13d
movzbl  %bh,%esi
xorl 2(%r11,%rsi,8),%eax
shr  $16,%ebx
movzbl  %bl,%esi
xorl 1(%r11,%rsi,8),%ecx
movzbl  %bh,%ebx
xorl 4(%r11,%rbx,8),%edx
movl   2(%r11,%rdi,8),%ebx
xor  %r9,%rax
xorl 1(%r11,%r15,8),%ebx
xor  %r8,%rcx
xorl 4(%r11,%rbp,8),%ebx
xorl 3(%r11,%r13,8),%ebx
xor  %r10,%rbx
movl   20(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%r13d
movzbl  %dh,%edi
shr  $16,%edx
movzbl  %dl,%r14d
movzbl  %dh,%ebp
movl   3(%r11,%r13,8),%edx
xor  %rsi,%rdx
movzbl  %cl,%r13d
movzbl  %ch,%esi
xorl 2(%r11,%rsi,8),%edx
shr  $16,%ecx
movzbl  %cl,%r15d
movzbl  %ch,%esi
movl   4(%r11,%rbp,8),%ecx
xorl 3(%r11,%r13,8),%ecx
movzbl  %al,%r13d
movzbl  %ah,%ebp
xorl 2(%r11,%rbp,8),%ecx
shr  $16,%eax
movzbl  %al,%ebp
xorl 1(%r11,%rbp,8),%edx
movzbl  %ah,%ebp
movl   1(%r11,%r14,8),%eax
xorl 4(%r11,%rsi,8),%eax
xorl 3(%r11,%r13,8),%eax
movzbl  %bl,%r13d
movzbl  %bh,%esi
xorl 2(%r11,%rsi,8),%eax
shr  $16,%ebx
movzbl  %bl,%esi
xorl 1(%r11,%rsi,8),%ecx
movzbl  %bh,%ebx
xorl 4(%r11,%rbx,8),%edx
movl   2(%r11,%rdi,8),%ebx
xor  %r9,%rax
xorl 1(%r11,%r15,8),%ebx
xor  %r8,%rcx
xorl 4(%r11,%rbp,8),%ebx
xorl 3(%r11,%r13,8),%ebx
xor  %r10,%rbx
movl   24(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%r13d
movzbl  %dh,%edi
shr  $16,%edx
movzbl  %dl,%r14d
movzbl  %dh,%ebp
movl   3(%r11,%r13,8),%edx
xor  %rsi,%rdx
movzbl  %cl,%r13d
movzbl  %ch,%esi
xorl 2(%r11,%rsi,8),%edx
shr  $16,%ecx
movzbl  %cl,%r15d
movzbl  %ch,%esi
movl   4(%r11,%rbp,8),%ecx
xorl 3(%r11,%r13,8),%ecx
movzbl  %al,%r13d
movzbl  %ah,%ebp
xorl 2(%r11,%rbp,8),%ecx
shr  $16,%eax
movzbl  %al,%ebp
xorl 1(%r11,%rbp,8),%edx
movzbl  %ah,%ebp
movl   1(%r11,%r14,8),%eax
xorl 4(%r11,%rsi,8),%eax
xorl 3(%r11,%r13,8),%eax
movzbl  %bl,%r13d
movzbl  %bh,%esi
xorl 2(%r11,%rsi,8),%eax
shr  $16,%ebx
movzbl  %bl,%esi
xorl 1(%r11,%rsi,8),%ecx
movzbl  %bh,%ebx
xorl 4(%r11,%rbx,8),%edx
movl   2(%r11,%rdi,8),%ebx
xorl 1(%r11,%r15,8),%ebx
xorl 4(%r11,%rbp,8),%ebx
xor  %r8,%rcx
xorl 3(%r11,%r13,8),%ebx
xor  %r9,%rax
xor  %r10,%rbx
movl   28(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%r13d
movzbl  %dh,%edi
shr  $16,%edx
movzbl  %dl,%r14d
movzbl  %dh,%ebp
movl   3(%r11,%r13,8),%edx
xor  %rsi,%rdx
movzbl  %cl,%r13d
movzbl  %ch,%esi
xorl 2(%r11,%rsi,8),%edx
shr  $16,%ecx
movzbl  %cl,%r15d
movzbl  %ch,%esi
movl   4(%r11,%rbp,8),%ecx
xorl 3(%r11,%r13,8),%ecx
movzbl  %al,%r13d
movzbl  %ah,%ebp
xorl 2(%r11,%rbp,8),%ecx
shr  $16,%eax
movzbl  %al,%ebp
xorl 1(%r11,%rbp,8),%edx
movzbl  %ah,%ebp
movl   1(%r11,%r14,8),%eax
xorl 4(%r11,%rsi,8),%eax
xorl 3(%r11,%r13,8),%eax
movzbl  %bl,%r13d
movzbl  %bh,%esi
xorl 2(%r11,%rsi,8),%eax
shr  $16,%ebx
movzbl  %bl,%esi
xorl 1(%r11,%rsi,8),%ecx
movzbl  %bh,%ebx
xorl 4(%r11,%rbx,8),%edx
movl   2(%r11,%rdi,8),%ebx
xorl 1(%r11,%r15,8),%ebx
xorl 4(%r11,%rbp,8),%ebx
xor  %r8,%rcx
xorl 3(%r11,%r13,8),%ebx
xor  %r9,%rax
xor  %r10,%rbx
movl   32(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%r13d
movzbl  %dh,%edi
shr  $16,%edx
movzbl  %dl,%r14d
movzbl  %dh,%ebp
movl   3(%r11,%r13,8),%edx
xor  %rsi,%rdx
movzbl  %cl,%r13d
movzbl  %ch,%esi
xorl 2(%r11,%rsi,8),%edx
shr  $16,%ecx
movzbl  %cl,%r15d
movzbl  %ch,%esi
movl   4(%r11,%rbp,8),%ecx
xorl 3(%r11,%r13,8),%ecx
movzbl  %al,%r13d
movzbl  %ah,%ebp
xorl 2(%r11,%rbp,8),%ecx
shr  $16,%eax
movzbl  %al,%ebp
xorl 1(%r11,%rbp,8),%edx
movzbl  %ah,%ebp
movl   1(%r11,%r14,8),%eax
xorl 4(%r11,%rsi,8),%eax
xorl 3(%r11,%r13,8),%eax
movzbl  %bl,%r13d
movzbl  %bh,%esi
xorl 2(%r11,%rsi,8),%eax
shr  $16,%ebx
movzbl  %bl,%esi
xorl 1(%r11,%rsi,8),%ecx
movzbl  %bh,%ebx
xorl 4(%r11,%rbx,8),%edx
movl   2(%r11,%rdi,8),%ebx
xorl 1(%r11,%r15,8),%ebx
xorl 4(%r11,%rbp,8),%ebx
xor  %r8,%rcx
xorl 3(%r11,%r13,8),%ebx
xor  %r9,%rax
xor  %r10,%rbx
movl   36(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%r13d
movzbl  %dh,%edi
shr  $16,%edx
movzbl  %dl,%r14d
movzbl  %dh,%ebp
movl   3(%r11,%r13,8),%edx
xor  %rsi,%rdx
movzbl  %cl,%r13d
movzbl  %ch,%esi
xorl 2(%r11,%rsi,8),%edx
shr  $16,%ecx
movzbl  %cl,%r15d
movzbl  %ch,%esi
movl   4(%r11,%rbp,8),%ecx
xorl 3(%r11,%r13,8),%ecx
movzbl  %al,%r13d
movzbl  %ah,%ebp
xorl 2(%r11,%rbp,8),%ecx
shr  $16,%eax
movzbl  %al,%ebp
xorl 1(%r11,%rbp,8),%edx
movzbl  %ah,%ebp
movl   1(%r11,%r14,8),%eax
xorl 4(%r11,%rsi,8),%eax
xorl 3(%r11,%r13,8),%eax
movzbl  %bl,%r13d
movzbl  %bh,%esi
xorl 2(%r11,%rsi,8),%eax
shr  $16,%ebx
movzbl  %bl,%esi
xorl 1(%r11,%rsi,8),%ecx
movzbl  %bh,%ebx
xorl 4(%r11,%rbx,8),%edx
movl   2(%r11,%rdi,8),%ebx
xorl 1(%r11,%r15,8),%ebx
xorl 4(%r11,%rbp,8),%ebx
xor  %r8,%rcx
xorl 3(%r11,%r13,8),%ebx
xor  %r9,%rax
xor  %r10,%rbx
movl   40(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%r13d
movzbl  %dh,%edi
shr  $16,%edx
movzbl  %dl,%r14d
movzbl  %dh,%ebp
movl   3(%r11,%r13,8),%edx
xor  %rsi,%rdx
movzbl  %cl,%r13d
movzbl  %ch,%esi
xorl 2(%r11,%rsi,8),%edx
shr  $16,%ecx
movzbl  %cl,%r15d
movzbl  %ch,%esi
movl   4(%r11,%rbp,8),%ecx
xorl 3(%r11,%r13,8),%ecx
movzbl  %al,%r13d
movzbl  %ah,%ebp
xorl 2(%r11,%rbp,8),%ecx
shr  $16,%eax
movzbl  %al,%ebp
xorl 1(%r11,%rbp,8),%edx
movzbl  %ah,%ebp
movl   1(%r11,%r14,8),%eax
xorl 4(%r11,%rsi,8),%eax
xorl 3(%r11,%r13,8),%eax
movzbl  %bl,%r13d
movzbl  %bh,%esi
xorl 2(%r11,%rsi,8),%eax
shr  $16,%ebx
movzbl  %bl,%esi
xorl 1(%r11,%rsi,8),%ecx
movzbl  %bh,%ebx
xorl 4(%r11,%rbx,8),%edx
movl   2(%r11,%rdi,8),%ebx
xorl 1(%r11,%r15,8),%ebx
xorl 4(%r11,%rbp,8),%ebx
xor  %r8,%rcx
xorl 3(%r11,%r13,8),%ebx
xor  %r9,%rax
xor  %r10,%rbx
movl   44(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%r13d
movzbl  %dh,%edi
shr  $16,%edx
movzbl  %dl,%r14d
movzbl  %dh,%ebp
movl   3(%r11,%r13,8),%edx
xor  %rsi,%rdx
movzbl  %cl,%r13d
movzbl  %ch,%esi
xorl 2(%r11,%rsi,8),%edx
shr  $16,%ecx
movzbl  %cl,%r15d
movzbl  %ch,%esi
movl   4(%r11,%rbp,8),%ecx
xorl 3(%r11,%r13,8),%ecx
movzbl  %al,%r13d
movzbl  %ah,%ebp
xorl 2(%r11,%rbp,8),%ecx
shr  $16,%eax
movzbl  %al,%ebp
xorl 1(%r11,%rbp,8),%edx
movzbl  %ah,%ebp
movl   1(%r11,%r14,8),%eax
xorl 4(%r11,%rsi,8),%eax
xorl 3(%r11,%r13,8),%eax
movzbl  %bl,%r13d
movzbl  %bh,%esi
xorl 2(%r11,%rsi,8),%eax
shr  $16,%ebx
movzbl  %bl,%esi
xorl 1(%r11,%rsi,8),%ecx
movzbl  %bh,%ebx
xorl 4(%r11,%rbx,8),%edx
movl   2(%r11,%rdi,8),%ebx
xorl 1(%r11,%r15,8),%ebx
xorl 4(%r11,%rbp,8),%ebx
xor  %r8,%rcx
xorl 3(%r11,%r13,8),%ebx
xor  %r9,%rax
xor  %r10,%rbx
movl   48(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%r13d
movzbl  %dh,%edi
shr  $16,%edx
movzbl  %dl,%r14d
movzbl  %dh,%ebp
movl   3(%r11,%r13,8),%edx
xor  %rsi,%rdx
movzbl  %cl,%r13d
movzbl  %ch,%esi
xorl 2(%r11,%rsi,8),%edx
shr  $16,%ecx
movzbl  %cl,%r15d
movzbl  %ch,%esi
movl   4(%r11,%rbp,8),%ecx
xorl 3(%r11,%r13,8),%ecx
movzbl  %al,%r13d
movzbl  %ah,%ebp
xorl 2(%r11,%rbp,8),%ecx
shr  $16,%eax
movzbl  %al,%ebp
xorl 1(%r11,%rbp,8),%edx
movzbl  %ah,%ebp
movl   1(%r11,%r14,8),%eax
xorl 4(%r11,%rsi,8),%eax
xorl 3(%r11,%r13,8),%eax
movzbl  %bl,%r13d
movzbl  %bh,%esi
xorl 2(%r11,%rsi,8),%eax
shr  $16,%ebx
movzbl  %bl,%esi
xorl 1(%r11,%rsi,8),%ecx
movzbl  %bh,%ebx
xorl 4(%r11,%rbx,8),%edx
movl   2(%r11,%rdi,8),%ebx
xorl 1(%r11,%r15,8),%ebx
xorl 4(%r11,%rbp,8),%ebx
xor  %r8,%rcx
xorl 3(%r11,%r13,8),%ebx
xor  %r9,%rax
xor  %r10,%rbx
movl   52(%r12),%esi
xor  %rsi,%r8
xor  %r8,%r9
xor  %r9,%r10
movzbl  %dl,%edi
movzbq 1(%r11,%rdi,8),%r12
movzbl  %dh,%edi
movzwq (%r11,%rdi,8),%r13
shr  $16,%edx
movzbl  %dl,%edi
movl   3(%r11,%rdi,8),%r14d
and  $0x00ff0000,%r14d
movzbl  %dh,%edi
movl   2(%r11,%rdi,8),%edx
and  $0xff000000,%edx
xor  %rsi,%r12
xor  %r10,%r13
xor  %r8,%rdx
xor  %r9,%r14
movzbl  %cl,%edi
movzbq 1(%r11,%rdi,8),%rdi
xor  %rdi,%rdx
movzbl  %ch,%edi
movzwq (%r11,%rdi,8),%rdi
xor  %rdi,%r12
shr  $16,%ecx
movzbl  %cl,%edi
movl   3(%r11,%rdi,8),%edi
and  $0x00ff0000,%edi
xor  %rdi,%r13
movzbl  %ch,%edi
movl   2(%r11,%rdi,8),%edi
and  $0xff000000,%edi
xor  %rdi,%r14
movzbl  %al,%edi
movzbq 1(%r11,%rdi,8),%rdi
xor  %rdi,%r14
movzbl  %ah,%edi
movzwq (%r11,%rdi,8),%rdi
xor  %rdi,%rdx
shr  $16,%eax
movzbl  %al,%edi
movl   3(%r11,%rdi,8),%edi
and  $0x00ff0000,%edi
xor  %rdi,%r12
movzbl  %ah,%edi
movl   2(%r11,%rdi,8),%edi
and  $0xff000000,%edi
xor  %rdi,%r13
movzbl  %bl,%edi
movzbq 1(%r11,%rdi,8),%rdi
xor  %rdi,%r13
movzbl  %bh,%edi
movzwq (%r11,%rdi,8),%rdi
xor  %rdi,%r14
shr  $16,%ebx
movzbl  %bl,%edi
movl   3(%r11,%rdi,8),%edi
and  $0x00ff0000,%edi
xor  %rdi,%rdx
movzbl  %bh,%edi
movl   2(%r11,%rdi,8),%edi
and  $0xff000000,%edi
xor  %rdi,%r12
movq 8(%rsp),%rdi
movl   %r12d,0(%rdi)
movl   %edx,4(%rdi)
movl   %r14d,8(%rdi)
movl   %r13d,12(%rdi)
movq 16(%rsp),%r11
movq 24(%rsp),%r12
movq 32(%rsp),%r13
movq 40(%rsp),%r14
movq 48(%rsp),%r15
movq 56(%rsp),%rbx
movq 64(%rsp),%rbp
add %r11,%rsp
ret