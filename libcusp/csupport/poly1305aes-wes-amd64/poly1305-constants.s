.data
.section .rodata
.p2align 5
.globl _poly1305_amd64_constants
.globl poly1305_amd64_constants
.globl poly1305_amd64_scale
.globl poly1305_amd64_two32
.globl poly1305_amd64_two64
.globl poly1305_amd64_two96
.globl poly1305_amd64_alpha32
.globl poly1305_amd64_alpha64
.globl poly1305_amd64_alpha96
.globl poly1305_amd64_alpha130
.globl poly1305_amd64_doffset0
.globl poly1305_amd64_doffset1
.globl poly1305_amd64_doffset2
.globl poly1305_amd64_doffset3
.globl poly1305_amd64_doffset3minustwo128
.globl poly1305_amd64_hoffset0
.globl poly1305_amd64_hoffset1
.globl poly1305_amd64_hoffset2
.globl poly1305_amd64_hoffset3
.globl poly1305_amd64_rounding
_poly1305_amd64_constants:
poly1305_amd64_constants:
poly1305_amd64_scale:
.long 0x0,0x37f40000
poly1305_amd64_two32:
.long 0x0,0x41f00000
poly1305_amd64_two64:
.long 0x0,0x43f00000
poly1305_amd64_two96:
.long 0x0,0x45f00000
poly1305_amd64_alpha32:
.long 0x0,0x45e80000
poly1305_amd64_alpha64:
.long 0x0,0x47e80000
poly1305_amd64_alpha96:
.long 0x0,0x49e80000
poly1305_amd64_alpha130:
.long 0x0,0x4c080000
poly1305_amd64_doffset0:
.long 0x0,0x43300000
poly1305_amd64_doffset1:
.long 0x0,0x45300000
poly1305_amd64_doffset2:
.long 0x0,0x47300000
poly1305_amd64_doffset3:
.long 0x0,0x49300000
poly1305_amd64_doffset3minustwo128:
.long 0x0,0x492ffffe
poly1305_amd64_hoffset0:
.long 0xfffffffb,0x43300001
poly1305_amd64_hoffset1:
.long 0xfffffffe,0x45300001
poly1305_amd64_hoffset2:
.long 0xfffffffe,0x47300001
poly1305_amd64_hoffset3:
.long 0xfffffffe,0x49300003
poly1305_amd64_rounding:
.byte 0x7f
.byte 0x13
