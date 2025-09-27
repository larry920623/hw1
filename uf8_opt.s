.text
j main

# -------- uf8_decode: a0=b -> a0=value --------
uf8_decode:
    srli t0, a0, 4          # e
    andi t1, a0, 0x0F       # m
    li   t2, 1
    sll  t2, t2, t0
    addi t2, t2, -1
    slli t2, t2, 4          # offset
    sll  t3, t1, t0
    add  a0, t3, t2
    ret

# -------- uf8_encode (optimized, no loop) --------
# e = floor(log2((v>>4)+1))
uf8_encode:
    li   t0, 16
    blt  a0, t0, Lret_v     # v<16 -> v

    srli t6, a0, 4          # x = (v>>4)
    addi t6, t6, 1          # x = (v>>4)+1
    addi t1, x0, 0          # e = 0

    li   t2, 256            # 1<<8
    blt  t6, t2, Lskip8
    srli t6, t6, 8
    addi t1, t1, 8
Lskip8:
    li   t2, 16             # 1<<4
    blt  t6, t2, Lskip4
    srli t6, t6, 4
    addi t1, t1, 4
Lskip4:
    li   t2, 4              # 1<<2
    blt  t6, t2, Lskip2
    srli t6, t6, 2
    addi t1, t1, 2
Lskip2:
    li   t2, 2              # 1<<1
    blt  t6, t2, Lskip1
    addi t1, t1, 1
Lskip1:
    # offset = ((1<<e)-1)<<4
    li   t2, 1
    sll  t2, t2, t1
    addi t2, t2, -1
    slli t2, t2, 4
    # mantissa & pack
    sub  t3, a0, t2
    srl  t3, t3, t1
    slli t4, t1, 4
    or   a0, t4, t3
    ret

Lret_v:
    ret

# ---------------- main / checker 同 baseline ----------------
main:
    la   s0, test_inputs
    la   s1, enc_out
    li   s2, 8
    addi s3, x0, 0
Lenc_loop:
    beq  s3, s2, Ldec_prep
    slli t0, s3, 2
    add  t1, s0, t0
    lw   a0, 0(t1)
    jal  ra, uf8_encode
    sw   a0, 0(s1)
    addi s1, s1, 4
    addi s3, s3, 1
    j    Lenc_loop

Ldec_prep:
    la   s1, enc_out
    la   s4, dec_out
    addi s3, x0, 0
Ldec_loop:
    beq  s3, s2, Lcheck_prep
    lw   a0, 0(s1)
    jal  ra, uf8_decode
    sw   a0, 0(s4)
    addi s1, s1, 4
    addi s4, s4, 4
    addi s3, s3, 1
    j    Ldec_loop

Lcheck_prep:
    la   s5, test_inputs
    la   s6, dec_out
    la   s7, check_out
    addi s3, x0, 0
Lchk_loop:
    beq  s3, s2, Ldone
    slli t0, s3, 2
    add  t1, s5, t0
    lw   t1, 0(t1)
    add  t2, s6, t0
    lw   t2, 0(t2)

    sub  t3, t2, t1
    blt  t3, x0, Lneg
    j    Labs
Lneg:
    sub  t3, x0, t3
Labs:
    slli t3, t3, 4

    beq  t1, x0, Lorig0
    bge  t1, t3, Lpass
    j    Lfail
Lorig0:
    bne  t2, x0, Lfail
Lpass:
    li   t4, 1
    j    Lstore
Lfail:
    li   t4, 0
Lstore:
    add  t5, s7, t0
    sw   t4, 0(t5)
    addi s3, s3, 1
    j    Lchk_loop

Ldone:
    j    Ldone

.data
test_inputs:
    .word 0,15,16,47,48,108,524272,1015792
enc_out:
    .word 0,0,0,0,0,0,0,0
dec_out:
    .word 0,0,0,0,0,0,0,0
check_out:
    .word 0,0,0,0,0,0,0,0 # all 1 if correct
