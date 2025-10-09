.text
j main

# =========================================================
# Problem C - BFloat16 encode / decode (bit-level)
# =========================================================
#  f32_to_bf16: a0 = f32 bits -> a0 = bf16 (lower 16 bits)
# =========================================================
f32_to_bf16:
    srli t0, a0, 16          # discard low 16 bits (shift right)
    li   t0, 0xFFFF    # 載入 16-bit 常數
    and  t1, a0, t0    # t1 = a0 & 0xFFFF
    li   t2, 0x8000          # rounding bit (MSB of discarded part)
    blt  t1, t2, Lno_round   # if < 0x8000, no rounding
    addi t0, t0, 1           # else round up
Lno_round:
    slli t0, t0, 16          # move bf16 to upper bits
    srli a0, t0, 16          # keep only lower 16 bits
    ret

# =========================================================
#  bf16_to_f32: a0 = bf16 -> a0 = f32 bits (zero-extend)
# =========================================================
bf16_to_f32:
    slli a0, a0, 16          # move bf16 bits to high 16 bits
    ret

# =========================================================
# Main: encode + decode test
# =========================================================
main:
    la   s0, test_f32        # input array (f32 bit patterns)
    la   s1, bf16_out        # output array (bf16)
    la   s2, recon_f32       # decoded array (reconstructed f32)
    li   s3, 8               # number of test cases
    addi s4, x0, 0

# ---- Encode ----
Lenc_loop:
    beq  s4, s3, Ldec_prep
    slli t0, s4, 2
    add  t1, s0, t0
    lw   a0, 0(t1)
    jal  ra, f32_to_bf16
    sw   a0, 0(s1)
    addi s1, s1, 4
    addi s4, s4, 1
    j    Lenc_loop

# ---- Decode ----
Ldec_prep:
    la   s1, bf16_out
    addi s4, x0, 0
Ldec_loop:
    beq  s4, s3, Ldone
    slli t0, s4, 2
    add  t1, s1, t0
    lw   a0, 0(t1)
    jal  ra, bf16_to_f32
    la   t2, recon_f32
    add  t2, t2, t0
    sw   a0, 0(t2)
    addi s4, s4, 1
    j    Ldec_loop

Ldone:
    j Ldone

# =========================================================
# Data section
# =========================================================
.data
# 以下是以 IEEE754 格式表示的 32-bit 浮點數
# 例如 1.0 = 0x3F800000
test_f32:
    .word 0x00000000   # 0.0
    .word 0x80000000   # -0.0
    .word 0x3F800000   # 1.0
    .word 0x3FC00000   # 1.5
    .word 0x41200000   # 10.0
    .word 0x7F800000   # +Inf
    .word 0xFF800000   # -Inf
    .word 0x7FC00000   # NaN

# 輸出緩衝區
bf16_out:
    .word 0,0,0,0,0,0,0,0
recon_f32:
    .word 0,0,0,0,0,0,0,0
