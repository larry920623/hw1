.text
j main                      # 從 main 進入

# -------- uf8_decode: a0=b -> a0=value --------
uf8_decode:
    srli t0, a0, 4          # e
    andi t1, a0, 0x0F       # m
    li   t2, 1
    sll  t2, t2, t0         # 1<<e
    addi t2, t2, -1         # (1<<e)-1
    slli t2, t2, 4          # offset = ((1<<e)-1)<<4
    sll  t3, t1, t0         # m<<e
    add  a0, t3, t2         # value
    ret

# -------- uf8_encode (baseline while找e) --------
uf8_encode:
    li   t0, 16
    blt  a0, t0, Lret_v     # v<16 -> v

    addi t1, x0, 0          # e
    addi t2, x0, 0          # offset
    li   t3, 16             # const 16
Lfind_e:
    slli t4, t2, 1
    add  t4, t4, t3         # next_offset = (offset<<1)+16
    blt  a0, t4, Lfound_e
    addi t2, t4, 0          # offset = next_offset
    addi t1, t1, 1          # e++
    li   t5, 15
    bge  t1, t5, Lfound_e   # guard e<=15
    j    Lfind_e
Lfound_e:
    sub  t6, a0, t2
    srl  t6, t6, t1         # mantissa
    slli t4, t1, 4
    or   a0, t4, t6         # (e<<4)|mantissa
    ret
Lret_v:
    ret

# ---------------- main ----------------
main:
    # encode: test_inputs -> enc_out
    la   s0, test_inputs
    la   s1, enc_out
    li   s2, 8              # N
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

# decode: enc_out -> dec_out
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

# check: |dec-orig|*16 <= orig  -> check_out[i]=1/0
Lcheck_prep:
    la   s5, test_inputs
    la   s6, dec_out
    la   s7, check_out
    addi s3, x0, 0
Lchk_loop:
    beq  s3, s2, Ldone
    slli t0, s3, 2
    add  t1, s5, t0
    lw   t1, 0(t1)          # orig
    add  t2, s6, t0
    lw   t2, 0(t2)          # dec

    sub  t3, t2, t1         # diff
    blt  t3, x0, Lneg
    j    Labs
Lneg:
    sub  t3, x0, t3         # abs(diff)
Labs:
    slli t3, t3, 4          # abs(diff)*16

    beq  t1, x0, Lorig0
    bge  t1, t3, Lpass      # (orig >= abs*16) -> pass
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

