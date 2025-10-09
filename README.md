# Assignment 1 

## How to run – UF8 (Problem B), RV32I (Ripes)
1. Open `uf8.s` in Ripes (desktop or web).
2. Assemble → Run.  
3. Memory → `.data` → check `intput` (0x10000000~0x1000001c), `enc_out` (0x10000020~0x0x100003c), `dec_out` (0x10000040~0x0x100005c), `check_out`        (0x10000060~0x0x100007c)(all 1 = pass).

## Files
- `uf8.s` – baseline (with checker)
- `uf8_opt.s` – optimized version (lookup/binsearch)

## Results
| Version | Inst. count (encode/dec) | Cycles (8 items encode+decode+check) | Notes |
|--------|--------------------------:|-----------------:|------|
| Baseline | 24 / 24 | 994 | while search for e |while search for e
| Optimized | 14 / 12 | 732 | lookup/binsearch |lookup/binsearch

## Pipeline notes
- Branch resolved in EX; mispredict flush = 1 bubble.
- Load-use hazard after `lw` → 1-cycle stall before consumer.

## How to run – bfloat16 (Problem C), RV32I (Ripes)
1. Open `bfloat16.s` in Ripes (desktop or web).
2. Assemble → Run.  
3. Memory → `.data` → check test_inputs (0x10000000~0x1000001c), bfloat16_out (0x10000020~0x1000002f), check_out (0x10000030~0x1000004f) (all 1 = pass).

## Files
- bfloat16.s – baseline (with checker)
