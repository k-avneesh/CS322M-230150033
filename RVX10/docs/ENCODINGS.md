# RVX10 Encodings — exact bitfields + worked examples

**Opcode:** CUSTOM‑0 = `0001011` (0x0B) — R‑type format

## Bitfield layout (R‑type)

```
31           25 24    20 19    15 14   12 11     7 6      0
+---------------+--------+--------+-------+--------+--------+
|   funct7      |  rs2   |  rs1   | funct3|   rd   | opcode |
+---------------+--------+--------+-------+--------+--------+
```

- `opcode` = `0001011`
- `rd`, `rs1`, `rs2` are integer registers (x0..x31)
- `funct7`/`funct3` select the specific RVX10 op (table below)

## funct7/funct3 map
| Op   | funct7   | funct3 |
|------|----------|--------|
| ANDN | 0000000  | 000    |
| ORN  | 0000000  | 001    |
| XNOR | 0000000  | 010    |
| MIN  | 0000001  | 000    |
| MAX  | 0000001  | 001    |
| MINU | 0000001  | 010    |
| MAXU | 0000001  | 011    |
| ROL  | 0000010  | 000    |
| ROR  | 0000010  | 001    |
| ABS* | 0000011  | 000    |

\* `ABS` ignores `rs2` (encode as x0).
## Worked encodings (used in tests)

| Op | Encoding fields | Hex | Binary (msb→lsb) |
|---|---|---|---|
| ANDN | `funct7=0000000 rs2=x11(11) rs1=x10(10) funct3=000 rd=x5(5) opcode=0001011` | `0x00b5028b` | `00000000101101010000001010001011` |
| ORN | `funct7=0000000 rs2=x11(11) rs1=x10(10) funct3=001 rd=x5(5) opcode=0001011` | `0x00b5128b` | `00000000101101010001001010001011` |
| XNOR | `funct7=0000000 rs2=x11(11) rs1=x10(10) funct3=010 rd=x5(5) opcode=0001011` | `0x00b5228b` | `00000000101101010010001010001011` |
| MIN | `funct7=0000001 rs2=x11(11) rs1=x10(10) funct3=000 rd=x5(5) opcode=0001011` | `0x02b5028b` | `00000010101101010000001010001011` |
| MAX | `funct7=0000001 rs2=x11(11) rs1=x10(10) funct3=001 rd=x5(5) opcode=0001011` | `0x02b5128b` | `00000010101101010001001010001011` |
| MINU | `funct7=0000001 rs2=x11(11) rs1=x10(10) funct3=010 rd=x5(5) opcode=0001011` | `0x02b5228b` | `00000010101101010010001010001011` |
| MAXU | `funct7=0000001 rs2=x11(11) rs1=x10(10) funct3=011 rd=x5(5) opcode=0001011` | `0x02b5328b` | `00000010101101010011001010001011` |
| ROL | `funct7=0000010 rs2=x11(11) rs1=x10(10) funct3=000 rd=x5(5) opcode=0001011` | `0x04b5028b` | `00000100101101010000001010001011` |
| ROR | `funct7=0000010 rs2=x11(11) rs1=x10(10) funct3=001 rd=x5(5) opcode=0001011` | `0x04b5128b` | `00000100101101010001001010001011` |
| ABS | `funct7=0000011 rs2=x0(0) rs1=x12(12) funct3=000 rd=x5(5) opcode=0001011` | `0x0606028b` | `00000110000001100000001010001011` |

> Check: All encodings above match the machine words in `tests/rvx10.hex`.
