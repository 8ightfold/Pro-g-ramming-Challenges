; FizzBuzz in 32 bit Unix NASM
; Written in 3 days
; Change MAX to change the total iterations
; ECX in _start contains the initial value / general counter

; Total iterations:
%define MAX 0xFF

global _start

    ; System calls
    %define KCALL int 0x80
    %define EXIT mov eax, 0x1
    %define FORK mov eax, 0x2
    %define READ mov eax, 0x3
    %define WRTE mov eax, 0x4
    %define OPEN mov eax, 0x5
    %define CLSE mov eax, 0x6

    ; Variable sizes
    %define BOOL 1
    %define BYTE 1
    %define CHAR 1
    %define UCHR 1
    %define WRD_ 2
    %define INTG 4
    %define UINT 4
    %define RET_ 4
    %define LONG 8
    %define LPTR 8
    %define SZ_T 8
    %define ARR_(type, cnt) cnt * type

    ; Special characters
    %define NULL 0x0
    %define NEWL 0xA

section .data
    fizz db "Fizz", NULL
    fizz_l equ $-fizz
    buzz db "Buzz", NULL
    buzz_l equ $-buzz
    n_ db NEWL, NULL
    n__l equ $-n_

section .rodata
    digits db "0123456789ABCDEFx", NEWL, NULL, 'n'

section .bss
    number   resb 16 ; Space for the number to be printed
   ;number_l resw 1  ; Space for the size of the number

section .text
jmp _start

;---------------------------------------------------------------------------------------------------------------------;
; Returns code pushed to esp ; Takes value from stack
; void return(int code)
@return:
    EXIT
    add esp, RET_
    mov bx, word [esp + 0] ; return code
    KCALL

;---------------------------------------------------------------------------------------------------------------------;
; Writes to console ; Takes values from stack
; void write(unsigned int file, char* msg, size_t len)
@write:
    WRTE
    add esp, RET_
    mov bx,   word [esp + 0]  ; File descriptor
    mov ecx, dword [esp + 4]  ; Message pointer
    mov edx, dword [esp + 12] ; Message length
    KCALL
    sub esp, RET_
    ret

;---------------------------------------------------------------------------------------------------------------------;
; Writes an address to console ; Takes value from edx
; void writeaddress(unsigned int num)
@writeaddress:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    cld
    sub esp, RET_ + LPTR + SZ_T + LONG + LONG + INTG
    mov word  [esp + 0],  0x1                   ; File descriptor
    mov dword [esp + 4], number                 ; String pointer
    mov dword [esp + 12], 16                    ; Size of string
   ;mov dword [esp + 16]                        ; Size of offset (must be cleared)
    mov dword [esp + 20], edx                   ; Number to print
   ;mov dword [esp + 24]                        ; Number of digits

    ; Clear string
    mov eax, number
    and dword [eax + 0],  0
    and dword [eax + 4],  0
    and dword [eax + 8],  0
    and dword [eax + 12], 0

    ; Push "0x0\n" to string
    mov ah, byte [digits + 0x11]  ; '0'
    mov al, byte [digits + 0x00]  ; '0'
    shl eax, 16
    mov ah, byte [digits + 0x10]  ; 'x'
    mov al, byte [digits + 0x00]  ; '0'

    ; Check if zero since the output of BSR with 0 bits is UB
    cmp edx, 0x0
    jne .@wnstart

    ; If zero
    mov [number + 0], dword eax                 ; "0x0\n"
    jmp .@wnterminate                           ; Skip calculations, print

    ; If non-zero, get string size
    .@wnstart:
    mov word [number + 0], ax                   ; "0x"
    xor eax, eax
    bsr eax, edx                                ; Get size of number in bits
    xor edx, edx
    mov ecx, 0x8
    div ecx
    lea ecx, [eax]
    lea eax, [(eax + 1) * 2]
    mov dword [esp + 16], eax

    ; REGISTERS
    xor eax, eax                  ; Load size
    xor ebx, ebx                  ; Byte calculation
   ;xor ecx, ecx                  ; Digit offset
    xor edx, edx                  ; Input offset
   ;xor esi, esi                  ; Characters + offset
   ;xor edi, edi                  ; Number + "0x" + digits

    mov eax, dword [esp + 16]
    lea edx, [esp + 20 + ecx]     ; Load 2-cycle offset
    lea edi, [number + 2]         ; Set DSI
    mov ecx, digits               ; Load digits

    mov bl, byte[edx]
    and ebx, 0b11110000
    shr bl, 4
    cmp ebx, 0
    jnz .@wnmleven
    dec eax
    jmp .@wnmlodd

    .@wnmainloop:
    mov bl, byte[edx]
    and ebx, 0b11110000
    shr bl, 4
    .@wnmleven:
    lea esi, [ecx + ebx]                  ; Load 1-cycle offset
    movsb
    dec eax

    .@wnmlodd:
    mov bl, byte[edx]
    and ebx, 0b00001111
    lea esi, [ecx + ebx]
    movsb                         ; Move letter to output string
    dec eax
    dec edx

    cmp eax, 0
    jnz .@wnmainloop

    ; Newline terminate string
    lea esi, [digits + 0x11]      ; Set ESI to '\n'
    movsb

    .@wnterminate:
    mov dword [esp + 16], 0
    call @write
    add esp, RET_ + LPTR + SZ_T + LONG + LONG + INTG
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

;---------------------------------------------------------------------------------------------------------------------;
; Writes an number to console in hex format ; Takes value from edx
; void writehexnumber(unsigned int num)
@writehexnumber:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    cld
    sub esp, RET_ + LPTR + SZ_T + LONG + LONG + INTG
    mov word  [esp + 0],  0x1                   ; File descriptor
    mov dword [esp + 4], number                 ; String pointer
    mov dword [esp + 12], 16                    ; Size of string
   ;mov dword [esp + 16]                        ; Size of offset (must be cleared)
    mov dword [esp + 20], edx                   ; Number to print
   ;mov dword [esp + 24]                        ; Number of digits

    ; Clear string
    mov eax, number
    and dword [eax + 0],  0
    and dword [eax + 4],  0
    and dword [eax + 8],  0
    and dword [eax + 12], 0

    ; Push "0\n" to string
    xor eax, eax
    mov ah, byte [digits + 0x11]  ; '0'
    mov al, byte [digits + 0x00]  ; '0'

    ; Check if zero since the output of BSR with 0 bits is UB
    cmp edx, 0x0
    jne .@whnstart

    ; If zero
    mov [number + 0], ax                         ; "0\n"
    jmp .@whnterminate                           ; Skip calculations, print

    ; If non-zero, get string size
    .@whnstart:
    xor eax, eax
    bsr eax, edx                                ; Get size of number in bits
    xor edx, edx
    mov ecx, 0x8
    div ecx
    lea ecx, [eax]
    lea eax, [(eax + 1) * 2]                    ; Get amount of characters to print
    mov dword [esp + 16], eax

    ; REGISTERS
    xor eax, eax                  ; Load size
    xor ebx, ebx                  ; Byte calculation
   ;xor ecx, ecx                  ; Digit offset
    xor edx, edx                  ; Input offset
   ;xor esi, esi                  ; Characters + offset
   ;xor edi, edi                  ; Number + "0x" + digits

    mov eax, dword [esp + 16]
    lea edx, [esp + 20 + ecx]     ; Load 2-cycle offset
    lea edi, [number]             ; Set DSI
    mov ecx, digits               ; Load digits

    mov bl, byte[edx]
    and ebx, 0b11110000
    shr bl, 4
    cmp ebx, 0
    jnz .@whnmleven
    dec eax
    jmp .@whnmlodd

    .@whnmainloop:
    mov bl, byte[edx]
    and ebx, 0b11110000
    shr bl, 4
    .@whnmleven:
    lea esi, [ecx + ebx]                  ; Load 1-cycle offset
    movsb
    dec eax

    .@whnmlodd:
    mov bl, byte[edx]
    and ebx, 0b00001111
    lea esi, [ecx + ebx]
    movsb                         ; Move letter to output string
    dec eax
    dec edx

    cmp eax, 0
    jnz .@whnmainloop

    ; Newline terminate string
    lea esi, [digits + 0x11]      ; Set ESI to '\n'
    movsb

    .@whnterminate:
    mov dword [esp + 16], 0
    call @write
    add esp, RET_ + LPTR + SZ_T + LONG + LONG + INTG
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

;---------------------------------------------------------------------------------------------------------------------;
; Sets a given memory location to the length of a null-terminated string ; Takes value from edx
; int strlen(char* msg)
@strlen:
    push edx
    mov eax, -1
    dec edx
    .@slmainloop:
        inc eax
        inc edx
        cmp byte [edx], 0
        jne .@slmainloop
    pop edx
    ret

;---------------------------------------------------------------------------------------------------------------------;
; Writes the null-terminated string at given memory location to the console ; Takes value from edx
; void writestring(char* msg)
@writestring:
    push eax
    push ebx
    push ecx
    push edx
    sub esp, RET_ + INTG + LPTR + SZ_T
    call @strlen
    mov  word [esp + 0],  0x1
    mov dword [esp + 4],  edx
    mov dword [esp + 12], eax
    call @write
    add esp, RET_ + INTG + LPTR + SZ_T
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

_start:
    ;---------------------------------------------------[MAIN LOOP]---------------------------------------------------;

    ; REGISTERS
    ; EAX: Modulo input (dividend)
    ; EBX: Modulo input (divisor)
    ; ECX: Iteration count
    ; EDX: Modulo output (remainder)
    ; ESI: Fizz/Buzz/Both/Null (0b00)

    mov ecx, 1  ; Starting value

.@mainloop:
    .@mlfizz:
        mov eax, ecx
        xor edx, edx
        mov ebx, 0x3
        div ebx
        cmp edx, 0
        jnz .@mlbuzz
        or esi, 0b01
    .@mlbuzz:
        mov eax, ecx
        xor edx, edx
        mov ebx, 0x5
        div ebx
        cmp edx, 0
        jnz .@mltest
        or esi, 0b10
    .@mltest:
        cmp esi, 0
        je .@mlzero
        cmp esi, 2
        je .@mlt2
        cmp esi, 3
        je .@mlt3
        .@mlt1:
            mov edx, fizz
            call @writestring
            mov edx, n_
            call @writestring
            jmp .@mlendloop
        .@mlt2:
            mov edx, buzz
            call @writestring
            mov edx, n_
            call @writestring
            jmp .@mlendloop
        .@mlt3:
            mov edx, fizz
            call @writestring
            mov edx, buzz
            call @writestring
            mov edx, n_
            call @writestring
            jmp .@mlendloop
    .@mlzero:
        mov edx, ecx
        call @writehexnumber
    .@mlendloop:
    xor edx, edx
    xor esi, esi
    inc ecx
    cmp ecx, MAX + 1
    jne .@mainloop

.@terminate:
    ; Return 0
    sub esp, INTG
    mov word [esp + 0], 0x0
    call @return
    
