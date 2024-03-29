.text
.p2align 5
.globl _aes128_amd64_2_expand
.globl aes128_amd64_2_expand
_aes128_amd64_2_expand:
aes128_amd64_2_expand:
mov %rsp,%r11
and $31,%r11
add $96,%r11
sub %r11,%rsp
movq %r11,0(%rsp)
movq %r12,8(%rsp)
movq %r13,16(%rsp)
movq %r14,24(%rsp)
movq %r15,32(%rsp)
movq %rdi,40(%rsp)
movq %rsi,48(%rsp)
movq %rbp,56(%rsp)
movq %rbx,64(%rsp)
movl   0(%rdx),%r8d
movl   4(%rdx),%r9d
movl   8(%rdx),%eax
movl   12(%rdx),%ebx
movl   %r8d,0(%rcx)
movl   %r9d,4(%rcx)
movl   %eax,8(%rcx)
movl   %ebx,12(%rcx)
lea  aes128_amd64_2_tablex(%rip),%rdx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r10
xor  $0x01,%r10d
movzbl  %bl,%r11d
rol  $16,%ebx
movl   2(%rdx,%r11,8),%r11d
and  $0xff000000,%r11d
xor  %r11,%r10
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%r11d
and  $0x00ff0000,%r11d
xor  %r11,%r10
movzbl  %bl,%r11d
rol  $16,%ebx
movzwq (%rdx,%r11,8),%r11
xor  %r11,%r10
xor  %r10,%r8
movl   %r8d,16(%rcx)
xor  %r8,%r9
xor  %r9,%rax
xor  %rax,%rbx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r10
xor  $0x02,%r10d
movzbl  %bl,%r11d
rol  $16,%ebx
movl   2(%rdx,%r11,8),%r11d
and  $0xff000000,%r11d
xor  %r11,%r10
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%r11d
and  $0x00ff0000,%r11d
xor  %r11,%r10
movzbl  %bl,%r11d
rol  $16,%ebx
movzwq (%rdx,%r11,8),%r11
xor  %r11,%r10
xor  %r10,%r8
movl   %r8d,20(%rcx)
xor  %r8,%r9
xor  %r9,%rax
xor  %rax,%rbx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r10
xor  $0x04,%r10d
movzbl  %bl,%r11d
rol  $16,%ebx
movl   2(%rdx,%r11,8),%r11d
and  $0xff000000,%r11d
xor  %r11,%r10
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%r11d
and  $0x00ff0000,%r11d
xor  %r11,%r10
movzbl  %bl,%r11d
rol  $16,%ebx
movzwq (%rdx,%r11,8),%r11
xor  %r11,%r10
xor  %r10,%r8
movl   %r8d,24(%rcx)
xor  %r8,%r9
xor  %r9,%rax
xor  %rax,%rbx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r10
xor  $0x08,%r10d
movzbl  %bl,%r11d
rol  $16,%ebx
movl   2(%rdx,%r11,8),%r11d
and  $0xff000000,%r11d
xor  %r11,%r10
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%r11d
and  $0x00ff0000,%r11d
xor  %r11,%r10
movzbl  %bl,%r11d
rol  $16,%ebx
movzwq (%rdx,%r11,8),%r11
xor  %r11,%r10
xor  %r10,%r8
movl   %r8d,28(%rcx)
xor  %r8,%r9
xor  %r9,%rax
xor  %rax,%rbx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r10
xor  $0x10,%r10d
movzbl  %bl,%r11d
rol  $16,%ebx
movl   2(%rdx,%r11,8),%r11d
and  $0xff000000,%r11d
xor  %r11,%r10
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%r11d
and  $0x00ff0000,%r11d
xor  %r11,%r10
movzbl  %bl,%r11d
rol  $16,%ebx
movzwq (%rdx,%r11,8),%r11
xor  %r11,%r10
xor  %r10,%r8
movl   %r8d,32(%rcx)
xor  %r8,%r9
xor  %r9,%rax
xor  %rax,%rbx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r10
xor  $0x20,%r10d
movzbl  %bl,%r11d
rol  $16,%ebx
movl   2(%rdx,%r11,8),%r11d
and  $0xff000000,%r11d
xor  %r11,%r10
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%r11d
and  $0x00ff0000,%r11d
xor  %r11,%r10
movzbl  %bl,%r11d
rol  $16,%ebx
movzwq (%rdx,%r11,8),%r11
xor  %r11,%r10
xor  %r10,%r8
movl   %r8d,36(%rcx)
xor  %r8,%r9
xor  %r9,%rax
xor  %rax,%rbx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r10
xor  $0x40,%r10d
movzbl  %bl,%r11d
rol  $16,%ebx
movl   2(%rdx,%r11,8),%r11d
and  $0xff000000,%r11d
xor  %r11,%r10
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%r11d
and  $0x00ff0000,%r11d
xor  %r11,%r10
movzbl  %bl,%r11d
rol  $16,%ebx
movzwq (%rdx,%r11,8),%r11
xor  %r11,%r10
xor  %r10,%r8
movl   %r8d,40(%rcx)
xor  %r8,%r9
xor  %r9,%rax
xor  %rax,%rbx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r10
xor  $0x80,%r10d
movzbl  %bl,%r11d
rol  $16,%ebx
movl   2(%rdx,%r11,8),%r11d
and  $0xff000000,%r11d
xor  %r11,%r10
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%r11d
and  $0x00ff0000,%r11d
xor  %r11,%r10
movzbl  %bl,%r11d
rol  $16,%ebx
movzwq (%rdx,%r11,8),%r11
xor  %r11,%r10
xor  %r10,%r8
movl   %r8d,44(%rcx)
xor  %r8,%r9
xor  %r9,%rax
xor  %rax,%rbx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r10
xor  $0x1b,%r10d
movzbl  %bl,%r11d
rol  $16,%ebx
movl   2(%rdx,%r11,8),%r11d
and  $0xff000000,%r11d
xor  %r11,%r10
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%r11d
and  $0x00ff0000,%r11d
xor  %r11,%r10
movzbl  %bl,%r11d
rol  $16,%ebx
movzwq (%rdx,%r11,8),%r11
xor  %r11,%r10
xor  %r10,%r8
movl   %r8d,48(%rcx)
xor  %r8,%r9
xor  %r9,%rax
xor  %rax,%rbx
movzbl  %bh,%edi
movzbq 1(%rdx,%rdi,8),%r9
xor  $0x36,%r9d
movzbl  %bl,%eax
rol  $16,%ebx
movl   2(%rdx,%rax,8),%eax
and  $0xff000000,%eax
xor  %rax,%r9
movzbl  %bh,%edi
movl   3(%rdx,%rdi,8),%eax
and  $0x00ff0000,%eax
xor  %rax,%r9
movzbl  %bl,%eax
rol  $16,%ebx
movzwq (%rdx,%rax,8),%rdx
xor  %rdx,%r9
xor  %r9,%r8
movl   %r8d,52(%rcx)
movq 0(%rsp),%r11
movq 8(%rsp),%r12
movq 16(%rsp),%r13
movq 24(%rsp),%r14
movq 32(%rsp),%r15
movq 40(%rsp),%rdi
movq 48(%rsp),%rsi
movq 56(%rsp),%rbp
movq 64(%rsp),%rbx
add %r11,%rsp
ret
