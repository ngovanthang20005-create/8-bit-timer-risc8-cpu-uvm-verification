; timer_demo.s - firmware for RISC-8 + Timer (assemble: python3 sw/asm8.py sw/timer_demo.s timer_demo.hex)
; Timer regs: F0 CTRL(b0 EN,b1 ONESHOT) F1 PRESC F2 LOAD F3 CMP F4 CNT FD IRQ_EN FE IRQ_STAT(W1C) FF ID
; Expected RAM at halt: 80=54 81=01 82=01 83=02 84=01 85=01 86=00 ; R4=E8 ; PWM pin 30% duty
; ---- A: read ID
    LDI  R7, 0xFF
    LD   R1, [R7]
    LDI  R6, 0x80
    ST   R1, [R6]        ; MEM[80] = 0x54
; ---- B: periodic PRESC=3 LOAD=24 CMP=10 (100 clocks); poll OVF twice
    LDI  R7, 0xF1
    LDI  R1, 3
    ST   R1, [R7]        ; PRESC
    LDI  R7, 0xF2
    LDI  R1, 24
    ST   R1, [R7]        ; LOAD
    LDI  R7, 0xF3
    LDI  R1, 10
    ST   R1, [R7]        ; CMP
    LDI  R7, 0xF0
    LDI  R1, 1
    ST   R1, [R7]        ; EN=1
    LDI  R7, 0xFE        ; R7 -> IRQ_STAT
    LDI  R2, 1           ; mask OVF (no ANDI)
waitB1:
    LD   R1, [R7]
    AND  R1, R1, R2      ; Z=1 if OVF not set
    BNZ  gotB1
    JMP  waitB1
gotB1:
    ST   R2, [R7]        ; W1C OVF
    LDI  R1, 1
    LDI  R6, 0x81
    ST   R1, [R6]        ; MEM[81] = 1 (first OVF)
    LDI  R7, 0xFE        ; R7 -> IRQ_STAT
    LDI  R2, 1           ; mask OVF (no ANDI)
waitB2:
    LD   R1, [R7]
    AND  R1, R1, R2      ; Z=1 if OVF not set
    BNZ  gotB2
    JMP  waitB2
gotB2:
    ST   R2, [R7]
    LDI  R1, 1
    LDI  R6, 0x82
    ST   R1, [R6]        ; MEM[82] = 1 (second OVF)
; ---- C: one-shot PRESC=0 LOAD=5; EN must clear by itself
    LDI  R7, 0xF0
    LDI  R1, 0
    ST   R1, [R7]        ; stop
    LDI  R7, 0xF1
    LDI  R1, 0
    ST   R1, [R7]        ; PRESC=0
    LDI  R7, 0xF2
    LDI  R1, 5
    ST   R1, [R7]        ; LOAD=5
    LDI  R7, 0xFE
    LDI  R1, 3
    ST   R1, [R7]        ; clear flags
    LDI  R7, 0xF0
    LDI  R1, 3
    ST   R1, [R7]        ; EN + ONESHOT
    LDI  R7, 0xFE        ; R7 -> IRQ_STAT
    LDI  R2, 1           ; mask OVF (no ANDI)
waitC:
    LD   R1, [R7]
    AND  R1, R1, R2      ; Z=1 if OVF not set
    BNZ  gotC
    JMP  waitC
gotC:
    LDI  R7, 0xF0
    LD   R1, [R7]        ; CTRL
    LDI  R6, 0x83
    ST   R1, [R6]        ; MEM[83] = 02 (EN self-cleared)
    LDI  R7, 0xFE
    LD   R1, [R7]        ; IRQ_STAT
    LDI  R6, 0x84
    ST   R1, [R6]        ; MEM[84] = 01 (only OVF)
; ---- D: irq pin: IRQ_EN=1, one-shot again, flag -> irq high, W1C -> irq low
    LDI  R7, 0xFE
    LDI  R1, 3
    ST   R1, [R7]        ; clear flags
    LDI  R7, 0xFD
    LDI  R1, 1
    ST   R1, [R7]        ; IRQ_EN = OVF
    LDI  R7, 0xF0
    LDI  R1, 3
    ST   R1, [R7]        ; EN + ONESHOT
    LDI  R7, 0xFE        ; R7 -> IRQ_STAT
    LDI  R2, 1           ; mask OVF (no ANDI)
waitD:
    LD   R1, [R7]
    AND  R1, R1, R2      ; Z=1 if OVF not set
    BNZ  gotD
    JMP  waitD
gotD:
    LDI  R7, 0xFE
    LD   R1, [R7]
    LDI  R6, 0x85
    ST   R1, [R6]        ; MEM[85] = 01 (irq high now)
    LDI  R1, 3
    ST   R1, [R7]        ; W1C
    LD   R1, [R7]
    LDI  R6, 0x86
    ST   R1, [R6]        ; MEM[86] = 00 (irq low)
; ---- E: PWM 30%: PRESC=0 LOAD=9 CMP=3, start, halt (timer keeps running)
    LDI  R7, 0xFD
    LDI  R1, 0
    ST   R1, [R7]        ; IRQ_EN=0
    LDI  R7, 0xF0
    LDI  R1, 0
    ST   R1, [R7]        ; stop
    LDI  R7, 0xF1
    LDI  R1, 0
    ST   R1, [R7]        ; PRESC=0
    LDI  R7, 0xF2
    LDI  R1, 9
    ST   R1, [R7]        ; LOAD=9
    LDI  R7, 0xF3
    LDI  R1, 3
    ST   R1, [R7]        ; CMP=3
    LDI  R7, 0xFE
    LDI  R1, 3
    ST   R1, [R7]        ; clear flags
    LDI  R7, 0xF0
    LDI  R1, 1
    ST   R1, [R7]        ; EN=1
; ---- F: ALU instruction whose operand is an I/O address must NOT touch the peripheral
    LDI  R7, 0xF4
    ADD  R4, R7, R7      ; R4 = 0xE8, no LD/ST -> io_cs must stay 0
    HLT
