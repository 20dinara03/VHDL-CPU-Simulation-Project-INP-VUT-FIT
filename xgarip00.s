; Autor reseni: Dinara Garipova xgarip00

; Projekt 2 - INP 2022
; Vernamova sifra na architekture MIPS64

; DATA SEGMENT
                .data
login:          .asciiz "xgarip00"  ; sem doplnte vas login
cipher:         .space  17  ; misto pro zapis sifrovaneho loginu

params_sys5:    .space  8   ; misto pro ulozeni adresy pocatku
                            ; retezce pro vypis pomoci syscall 5
                            ; (viz nize "funkce" print_string)

; CODE SEGMENT
                .text

                ; ZDE NAHRADTE KOD VASIM RESENIM
main:
                ;r1-r28-r17-r19-r0-r4
                start:
                lb r1,login(r17)
                sub r19, r19, r19
                addi r19, r19, 2
                slti r4, r1, 97
                bne r4, r0, end

                addi r28, r28, 1
                ddiv r28, r19
                mfhi r19
                beq r19, r0, even
                nop
                nop

                addi r1, r1, 7
                slti r4, r1, 122
                beq r4, r0, overflow
                nop
                nop
                j write
                nop
                nop
                
                even:
                addi r1, r1, -1
                slti r4, r1, 97
                bne r4, r0, min_overflow
                nop
                nop
                j write
                nop
                nop

                min_overflow:
                addi r1, r1, 26
                j write
                nop
                nop

                overflow:
                addi r1, r1, -26
                j write
                nop
                nop

                write:
                sb r1, cipher(r17)
                addi r17, r17, 1
                j start
                nop
                nop

                end:
                daddi r4, r0, cipher
                jal print_string    ; vypis pomoci print_string - viz nize
                syscall 0

print_string:   ; adresa retezce se ocekava v r4
                sw      r4, params_sys5(r0)
                daddi   r14, r0, params_sys5    ; adr pro syscall 5 musi do r14
                syscall 5   ; systemova procedura - vypis retezce na terminal
                jr      r31 ; return - r31 je urcen na return address
