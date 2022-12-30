; IO library for use with SASM.
; Written by Joe Norton September 2020.
; You are free to use this code but if you profit from it then you must buy me a cup of tea.
; And a biscuit.
; Only compatible with Linux x86_64.
; Version 6
;   strings_are_equal function added
; Version 5
;   minor changes
; Version 4
;   copy_string function added
;Version history:
; Version 3
;   Input functions implemented
; Version 2.
;   Save registers

; .special_data_section is a .data section with a special name
; calling it ".data" interferes with the .data section in the calling asm file
; there's a prize if someone can explain why (a biscuit)
section .special_data_section progbits alloc noexec write align=4
    msg_not_implemented db "This function is not implemented yet.", 0

section .special_bss_section nobits alloc noexec write align=4 
    small_buffer: resb 16
    input_buffer: resb 513
    output_buffer: resb 25

section .text

print_string_new:
;Print a string, RDI must contain a pointer to the NULL terminated string.
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rbx
    push rcx
    push rdx
    push rdi
    ;first we must work out how many chars to print (i.e.number of bytes before the NULL)
    mov rdx, 0 ; counter (this will be the number of chars to print
  .str_len_loop:
    lea rcx, [rdi + rdx] ; RCX points to the address indexed by RDX
    movzx rax, BYTE [rcx] ; move what is pointed to by RCX into RAX (need to zero extend)
    inc rdx ; increment the counter (we need to do this before the CMP 
            ; as there is a small chance of INC affecting the flags)
    cmp rax, 0 ; check if we are pointing to a NULL
    jne .str_len_loop ; loop if we are NOT pointing to a NULL
    dec rdx ; this will be one more than it should be, so take one away
    ; RDX now contains 8000000000000000the number of bytes BEFORE the NULL terminator
    ; i.e. the length of the string (excluding the NULL)
    mov rcx, rdi ; address of string to pring goes in rcx (this is the parameter passed in rdi)
    mov rax, 4   ; use the write (4) syscall
    mov rbx, 1   ; write to stdout (file descriptor 1)
    ; rdx already contains the number of bytes to write
    int 0x80     ; make syscall
    ;put the registers back how we found them
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    xor rax, rax ; return zero    
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function print_string_new

print_uint_new:
;Print the signed 64 bit integer value contained in the RDI register.
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rbx
    push rcx
    push rdx
    push rdi
    push r13
    push r15
    mov r13, output_buffer ; R13 points to output buffer (string)
    mov r15, 10 ; R15 contains the base (decimal)    mov rcx, rdi ; address of string to pring goes in rcx (this is the parameter passed in rdi)
    mov rcx, 10000000000000000000  ; 10^1rdi9 - RCX contains decimal value of highest (decimal) column of output
  .loop:
    mov rax, rdi ; prepare for division
    mov rdx, 0   ; prepare for division
    div rcx ; after division, rax contains the decimal digit of column
    add rax, 48 ; convert to ASCII digit
    mov rdi, rdx ; put remainder back in rdi for next loop
    mov BYTE [r13], al ; put ASCII character in output buffer (al is low 8 bits of rax)
    mov rax, rcx ; prepare for division
    mov rdx, 0   ; prepare for division
    div r15 ; divide column value by 10
    mov rcx, rax ; new value of highest (decimal) column of output
    inc r13 ; move along the output buffer by one byte
    cmp rcx, 0 ; last column has been dealt with
    jne .loop
    mov BYTE [r13], BYTE 0 ; put a NULL terminator on the end of the output string
    ; now move pointer along to first non-zero-char (ASCII(0x30)) character (to remove leading zeros)
    ; we know that buffer contains at least one char before the NULL
    lea rdi, [output_buffer - 1] ; one less because we are going to inc it in the loop
    mov al, 0x30 ; char('0')
  .loop2:
    inc rdi
    cmp BYTE [rdi], al ; if pointing to a leading '0' then move along
    je .loop2    
    cmp BYTE [rdi], BYTE 0 ; if we're pointing to the NULL then we need to go back by one ( we have '0'\0)
    jne .finish
    dec rdi
  .finish:
    ;RDI now points to the right place, so we display the string
    call print_string_new
    ;put the registers back how we found them
    pop r15
    pop r13
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    xor rax, rax ; return zero
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function print_uint_new

print_int_new:
; Print the signed 64 bit integer value contained in the RDI register.
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rbx
    push rcx
    push rdx
    push rdi
    ; first we look at the sign bit
    test rdi, rdi ; the sign flag will be set if the number is negative
    jns .finish ; if the number is positive, print it out as before
    ; negative, so print a '-' and then print the positive number
    mov BYTE [output_buffer], 0x2D ; '-'
    mov rcx, output_buffer ; address of string to pring goes in rcx (this is the parameter passed in rdi)
    mov rax, 4   ; use the write (4) syscall
    mov rbx, 1   ; write to stdout (file descriptor 1)
    mov rdx, 1   ; number of bytes to write
    int 0x80     ; make syscall   
    neg rdi ; negate the number and print the singed version
  .finish: ; print the positive number
    call print_uint_new ;positive
    ;put the registers back how we found them
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    xor rax, rax ; return zero 
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function print_int_new

print_nl_new:
;Print a new line, takes no parameters.
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rbx
    push rcx
    push rdx
    mov BYTE [output_buffer], 0x0A ; newline char
    mov rcx, output_buffer ; address of string to pring goes in rcx (this is the parameter passed in rdi)
    mov rax, 4   ; use the write (4) syscall
    mov rbx, 1   ; write to stdout (file descriptor 1)
    mov rdx, 1   ; number of bytes to write
    int 0x80     ; make syscall
    ;put the registers back how we found them
    pop rdx
    pop rcx
    pop rbx
    xor rax, rax ; return zero
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function print_nl_new

print_char_new:
; Print an ASCII character using an ASCII character code stored in the RDI register.
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rbx
    push rcx
    push rdx
    mov BYTE [output_buffer], dil ; dil is the 8-bit low-end register of rdi
    mov rcx, output_buffer ; address of string to pring goes in rcx
    mov rax, 4   ; use the write (4) syscall
    mov rbx, 1   ; write to stdout (file descriptor 1)
    mov rdx, 1   ; number of bytes to write
    int 0x80     ; make syscall
    ;put the registers back how we found them
    pop rdx
    pop rcx
    pop rbx
    xor rax, rax ; return zero 
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function print_char_new

read_char_new:
; Read an ASCII character code from console input into RAX (will be the first character if more than one).
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rbx
    push rcx
    push rdx
    mov     rdx, 1              ; number of bytes to read
    mov     rcx, small_buffer   ; buffer to store our input
    mov     rbx, 0              ; write to the STDIN file
    mov     rax, 3              ; invoke SYS_READ (kernel opcode 3)
    int     80h
    movzx rax, BYTE [small_buffer]
    ;put the registers back how we found them
    pop rdx
    pop rcx
    pop rbx
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function read_char_new

read_string_new:
;Read a string from console input, and put a pointer to it in RAX.
;Notes on this function:
;     1 -The string returned in the buffer is only valid until you next call the function.
;        After the next call to the function the buffer is overwritten with the new input.
;     2 -The function needs a linefeed (ASCII 10 decimal) to signify the end of the line.
;        If using this function in SASM, make sure your last string has a linefeed after it.
;     3 -This is not an efficient way to read a string from STDIN. It is written like this in
;        order to be compatible with SASM. It makes a separate kernel call each time it
;        reads a char - semantically fine but not at all efficient.
;     4 -This function uses a static buffer and cannot accept a string of more than 512 chars.
;        If you want more, fiddle with the size of the input_buffer above.
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push r13
    mov r13, input_buffer ; point r13 to input buffer
  .loop:
    call read_char_new
    ; if we got a linefeed (dec 10) then put a NULL on the output string and finish
    cmp al, 10
    je .finish
    mov BYTE [r13], al ; put the returned char into the output buffer
    inc r13 ; move to next char in output buffer
    jmp .loop
  .finish:
    mov BYTE [r13], 0 ; put a NULL on the end of the output string
    ;put the registers back how we found them
    pop r13
    mov rax, input_buffer ; return pointer to output buffer in RAX
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function read_string_new

atoi:
;Convert number string pointed to by RDI to a 64 bit integer.
;Code for atoi stolen from: https://gist.github.com/tnewman/63b64284196301c4569f750a08ef52b2
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rsi
    push rdi
    mov rax, 0              ; Set initial total to 0  
  .convert:
    movzx rsi, byte [rdi]   ; Get the current character
    test rsi, rsi           ; Check for \0
    je .done    
    cmp rsi, 48             ; Anything less than 0 is invalid
    jl .error    
    cmp rsi, 57             ; Anything greater than 9 is invalid
    jg .error     
    sub rsi, 48             ; Convert from ASCII to decimal 
    imul rax, 10            ; Multiply total by 10
    add rax, rsi            ; Add current digit to total    
    inc rdi                 ; Get the address of the next character
    jmp .convert
  .error:
    mov rax, 0xFFFFFFFFFFFFFFFF  ; Return ULLONG_MAX on error 
  .done:
    ;put the registers back how we found them
    pop rdi
    pop rsi
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret                     ; Return total or error code

read_uint_new:
;Read a unsigned 64 bit integer value from the console and store the result in the RAX register.
;If the string entered in not a valid number then the output will be undefined
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rsi
    push rdi
    call read_string_new
    ;rax now points to string buffer
    mov rdi, rax ; point rdi to string buffer to pass to atoi
    call atoi
    ;value is now in rax, ready for return
    ;put the registers back how we found them
    pop rdi
    pop rsi
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function read_uint_new

read_int_new:
;Read a signed 64 bit integer value from the console and store the result in the RAX register.
;If the string entered in not a valid number then the output will be undefined
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rdi
    call read_string_new
    ; RAX points to the string
    mov rdi, rax ; put string pointer in rdi
    cmp BYTE [rdi], 0x2d; ASCII(-) check for minus sign in first byte of string
    jne .is_not_negative
    ;is negative, so move pointer (r13) along one byte
    inc rdi ; move past the minus char
    call atoi ; convert the unsigned part to integer (returned in EAX)
    neg rax
    jmp .finish
  .is_not_negative:
    call atoi
  .finish:
    ;put the registers back how we found them
    pop rdi
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function read_int_new

copy_string:
;Copy srtring pointed to by RSI (source) into string pointed to by RDI (destination)
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rdi
    push rsi
  .loop:
    mov al, BYTE [rsi]
    mov BYTE [rdi], al
    inc rsi ; point to next byte
    inc rdi ; point to next byte
    cmp al, 0 ; check if we just copied a NULL (end of string)
    jne .loop
    ;put the registers back how we found them
    pop rsi
    pop rdi
    xor rax, rax ; return zero
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function copy_string
    
strings_are_equal:
; Compares strings pointed to by RDI and RSI. Returns 1 if equal, zero otherwise (in RAX)
; Strings must be null terminated - you have been warned!
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rbx
    push rdi
    push rsi
  .loop:
    mov bl, BYTE [rdi]
    cmp BYTE [rsi], bl
    je .equal
    ;not equal - return zero
    xor rax, rax
    jmp .finish
  .equal:
    mov rax, 1 ; return 1 if we're at the end of the strings
    cmp bl, 0 ; finish if we're on a NULL
                ; Note that if we are here and either string is on a NULL then
                ; they are both on a NULL, so we only have to check one of them
    je .finish
    inc rdi ; move to next byte in the string
    inc rsi ; move to next byte in the string
    jmp .loop
  .finish:
    ;put the registers back how we found them
    pop rsi
    pop rdi
    pop rbx
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; End function strings_are_equal

print_address_new:
; Print the pointer value contained in the RDI register (in hexadecimal).
; This function doesn't work properly yet
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push rdi
    mov rdi, msg_not_implemented
    call print_string_new
    call print_nl_new
    pop rdi
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
    ;create a stack frame
    push rbp
    mov rbp, rsp
    sub rsp,32 
    ;just to make sure, we are going to push all the registers we use onto the stack
    push rdi
    mov rcx, output_buffer ; RCX contains pointer to output_buffer
    mov WORD [rcx], 0x7830 ; '0x'
    add rcx, 2 ; move along the output string
    cmp rdi, 0 ; if it is zero then return '0x0'
    jne .loop ; if non-zero then start the loop
    mov BYTE [rcx], 0x30 ; '0' char
    inc rcx
    jmp .finished
  .loop:
    mov al, dil
    mov bl, dil
    and al, 0x0F ; mask off the top 4 bits of al
    shr bl, 4 ; move the high four bits to the low end of ah (zeroing the top end)
    ; convert to ASCII chars
    cmp al, 9
    jg .al_is_char
    add al, 48 ; hex value in the range 0-9
    jmp .al_conversion_finished
  .al_is_char: ; hex value in the range A-F
    add al, 55
  .al_conversion_finished:   
    cmp bl, 9
    jg .bl_is_char
    add bl, 48 ; hex value in the range 0-9
    jmp .bl_conversion_finished
  .bl_is_char: ; hex value in the range A-F
    add bl, 55
  .bl_conversion_finished:
    ; now al and bl contain correct ASCII values
    mov BYTE [rcx], bl
    mov BYTE [rcx + 1], al
    add rcx, 2
    shr rdi, 8 ; do next 8 bits
    cmp rdi, 0 ; finish if rdi is zero
    jne .loop ; loop again if rdi is non-zero
  .finished:
    mov BYTE [rcx], 0 ; append the NULL to the string
    mov rdi, output_buffer
    call print_string_new
    ;put the registers back how we found them
    pop rdi
    xor rax, rax
    ;leave stack frame
    add rsp, 32
    pop rbp
    ret ; end function print_address_new
