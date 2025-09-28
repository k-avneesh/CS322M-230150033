# TESTPLAN — RVX10 ops (per-op inputs & expected results)

## Inputs
- `x10` (a) = `0x000000F0` (240)
- `x11` (b) = `0x0000000D` (13) → shift amount = `13`
- `x12`      = `-5` (for ABS)
- Checksum register: `x28` accumulates sum of each op’s result (wraps mod 2^32).

## Expected results per op

| Op   | Definition                    | rs1 | rs2    | rd (hex)  | rd (dec) |
|------|-------------------------------|-----|--------|-----------|----------|
| ANDN | rd = rs1 & ~rs2 | x10 | x11 | 0x000000F0 | 240 |
| ORN | rd = rs1 | ~rs2 | x10 | x11 | 0xFFFFFFF2 | 4294967282 |
| XNOR | rd = ~(rs1 ^ rs2) | x10 | x11 | 0xFFFFFF02 | 4294967042 |
| MIN | rd = min(rs1,rs2) (s) | x10 | x11 | 0x0000000D | 13 |
| MAX | rd = max(rs1,rs2) (s) | x10 | x11 | 0x000000F0 | 240 |
| MINU | rd = min(rs1,rs2) (u) | x10 | x11 | 0x0000000D | 13 |
| MAXU | rd = max(rs1,rs2) (u) | x10 | x11 | 0x000000F0 | 240 |
| ROL | rd = rol(rs1, rs2[4:0]) | x10 | x11 | 0x001E0000 | 1966080 |
| ROR | rd = ror(rs1, rs2[4:0]) | x10 | x11 | 0x07800000 | 125829120 |
| ABS | rd = abs(rs1) | x12 | - | 0x00000005 | 5 |

## Checksum
- Sum of all rd values (mod 2^32) → `x28 = 0x079E01E3` (127795683)

## Program end (bench constraints)
- First store: `sw x0, 96(x0)`.
- Success store: `addi x2, x0, 25` then `sw x2, 100(x0)`.

## 230150033
