.text
.p2align 5
.globl _aes128_amd64_2_expand
.globl aes128_amd64_2_expand
_aes128_amd64_2_expand:
aes128_amd64_2_expand:
mov %rsp,%r11
and $31,%r11
add $64,%r11
sub %r11,%rsp
movq %r11,0(%rsp)
movq %r12,8(%rsp)
movq %r13,16(%rsp)
movq %r14,24(%rsp)
movq %r15,32(%rsp)
movq %rbx,40(%rsp)
movq %rbp,48(%rsp)
movl   0(%rsi),%edx
movl   4(%rsi),%ecx
movl   8(%rsi),%r8d
movl   12(%rsi),%ebx
movl   %edx,0(%rdi)
movl   %ecx,4(%rdi)
movl   %r8d,8(%rdi)
movl   %ebx,12(%rdi)
lea  aes128_amd64_2_tablex(%rip),%rsi
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%r9
xor  $0x01,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rsi,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rsi,%rax,8),%rax
xor  %rax,%r9
xor  %r9,%rdx
movl   %edx,16(%rdi)
xor  %rdx,%rcx
xor  %rcx,%r8
xor  %r8,%rbx
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%r9
xor  $0x02,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rsi,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rsi,%rax,8),%rax
xor  %rax,%r9
xor  %r9,%rdx
movl   %edx,20(%rdi)
xor  %rdx,%rcx
xor  %rcx,%r8
xor  %r8,%rbx
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%r9
xor  $0x04,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rsi,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rsi,%rax,8),%rax
xor  %rax,%r9
xor  %r9,%rdx
movl   %edx,24(%rdi)
xor  %rdx,%rcx
xor  %rcx,%r8
xor  %r8,%rbx
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%r9
xor  $0x08,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rsi,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rsi,%rax,8),%rax
xor  %rax,%r9
xor  %r9,%rdx
movl   %edx,28(%rdi)
xor  %rdx,%rcx
xor  %rcx,%r8
xor  %r8,%rbx
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%r9
xor  $0x10,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rsi,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rsi,%rax,8),%rax
xor  %rax,%r9
xor  %r9,%rdx
movl   %edx,32(%rdi)
xor  %rdx,%rcx
xor  %rcx,%r8
xor  %r8,%rbx
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%r9
xor  $0x20,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rsi,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rsi,%rax,8),%rax
xor  %rax,%r9
xor  %r9,%rdx
movl   %edx,36(%rdi)
xor  %rdx,%rcx
xor  %rcx,%r8
xor  %r8,%rbx
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%r9
xor  $0x40,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rsi,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rsi,%rax,8),%rax
xor  %rax,%r9
xor  %r9,%rdx
movl   %edx,40(%rdi)
xor  %rdx,%rcx
xor  %rcx,%r8
xor  %r8,%rbx
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%r9
xor  $0x80,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rsi,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rsi,%rax,8),%rax
xor  %rax,%r9
xor  %r9,%rdx
movl   %edx,44(%rdi)
xor  %rdx,%rcx
xor  %rcx,%r8
xor  %r8,%rbx
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%r9
xor  $0x1b,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rsi,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rsi,%rax,8),%rax
xor  %rax,%r9
xor  %r9,%rdx
movl   %edx,48(%rdi)
xor  %rdx,%rcx
xor  %rcx,%r8
xor  %r8,%rbx
movzbl  %bh,%ebp
movzbq 1(%rsi,%rbp,8),%rcx
xor  $0x36,%ecx
movzbl  %bl,%r8d
rol  $16,%ebx
movl   2(%rsi,%r8,8),%r8d
and  $0xff000000,%r8d
xor  %r8,%rcx
movzbl  %bh,%ebp
movl   3(%rsi,%rbp,8),%r8d
and  $0x00ff0000,%r8d
xor  %r8,%rcx
movzbl  %bl,%r8d
rol  $16,%ebx
movzwq (%rsi,%r8,8),%rsi
xor  %rsi,%rcx
xor  %rcx,%rdx
movl   %edx,52(%rdi)
movq 0(%rsp),%r11
movq 8(%rsp),%r12
movq 16(%rsp),%r13
movq 24(%rsp),%r14
movq 32(%rsp),%r15
movq 40(%rsp),%rbx
movq 48(%rsp),%rbp
add %r11,%rsp
ret
