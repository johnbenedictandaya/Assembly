section .data
    prompt1     db "Enter the first number (0-99): ",0
    len1        equ $ - prompt1

    prompt2     db "Enter the second number (0-99): ",0
    len2        equ $ - prompt2

    promptOp    db "Enter operation (+,-,*,/): ",0
    lenOp       equ $ - promptOp

    promptCont  db "Press Enter to continue or 'q' to quit: ",0
    lenCont     equ $ - promptCont

    newline     db 10,0
    errDivZero  db "Error: Division by zero!",10,0
    lenErrDiv   equ $ - errDivZero

section .bss
    buf1    resb 8
    buf2    resb 8
    bufOp   resb 8
    bufCont resb 8
    num1    resd 1
    num2    resd 1
    result  resd 1
    outbuf  resb 8

section .text
    global _start

_start:
main_loop:
    ; First number
    mov eax,4
    mov ebx,1
    mov ecx,prompt1
    mov edx,len1
    int 0x80

    mov eax,3
    mov ebx,0
    mov ecx,buf1
    mov edx,8
    int 0x80
    call trim_newline
    mov ecx,buf1
    call ascii_to_int
    mov [num1],eax

    ; Second number
    mov eax,4
    mov ebx,1
    mov ecx,prompt2
    mov edx,len2
    int 0x80

    mov eax,3
    mov ebx,0
    mov ecx,buf2
    mov edx,8
    int 0x80
    call trim_newline
    mov ecx,buf2
    call ascii_to_int
    mov [num2],eax

    ; Operation
    mov eax,4
    mov ebx,1
    mov ecx,promptOp
    mov edx,lenOp
    int 0x80

    mov eax,3
    mov ebx,0
    mov ecx,bufOp
    mov edx,8
    int 0x80
    call trim_newline

    mov al,[bufOp]
    cmp al,'+'
    je do_add
    cmp al,'-'
    je do_sub
    cmp al,'*'
    je do_mul
    cmp al,'/'
    je do_div
    jmp cont_prompt

do_add:
    mov eax,[num1]
    add eax,[num2]
    mov [result],eax
    jmp print_result

do_sub:
    mov eax,[num1]
    sub eax,[num2]
    mov [result],eax
    jmp print_result

do_mul:
    mov eax,[num1]
    mov ebx,[num2]
    mul ebx
    mov [result],eax
    jmp print_result

do_div:
    mov ebx,[num2]
    cmp ebx,0
    je div_zero
    mov eax,[num1]
    xor edx,edx
    div ebx
    mov [result],eax
    jmp print_result

div_zero:
    mov eax,4
    mov ebx,1
    mov ecx,errDivZero
    mov edx,lenErrDiv
    int 0x80
    jmp cont_prompt

print_result:
    mov eax,[result]
    mov ecx,outbuf
    call int_to_ascii
    mov eax,4
    mov ebx,1
    mov ecx,outbuf
    mov edx,8
    int 0x80

cont_prompt:
    mov eax,4
    mov ebx,1
    mov ecx,promptCont
    mov edx,lenCont
    int 0x80

    mov eax,3
    mov ebx,0
    mov ecx,bufCont
    mov edx,8
    int 0x80
    call trim_newline
    cmp byte [bufCont],'q'
    je exit_prog
    jmp main_loop

; Removes newline (0x0A) from buffer
trim_newline:
    mov ecx,eax       ; eax = bytes read
    mov esi,buf1
    cmp esi,buf2
    jb .checkOp
.checkBuf:
    mov esi,ecx
    mov edi,buf1
    jmp .scan
.checkOp:
    mov edi,buf2
.scan:
    mov ecx,eax
    mov esi,edi
    xor eax,eax
.remove:
    cmp byte [esi],10
    jne .skip
    mov byte [esi],0
.skip:
    inc esi
    loop .remove
    ret

; Converts ASCII to int
ascii_to_int:
    push ebx
    push edx
    xor eax,eax
    xor ebx,ebx
.next_char:
    mov dl,[ecx]
    cmp dl,10
    je .done
    cmp dl,0
    je .done
    sub dl,'0'
    cmp dl,9
    ja .done
    imul eax,eax,10
    add eax,edx
    inc ecx
    jmp .next_char
.done:
    pop edx
    pop ebx
    ret

; Converts integer in EAX to ASCII string at ECX
int_to_ascii:
    push ebx
    push edx
    push esi
    mov ebx,10
    mov esi,ecx
    add esi,6
    mov byte [esi],0
    dec esi
.intloop:
    xor edx,edx
    div ebx
    add dl,'0'
    mov [esi],dl
    dec esi
    test eax,eax
    jnz .intloop
    inc esi
.copyloop:
    mov al,[esi]
    mov [ecx],al
    inc esi
    inc ecx
    cmp al,0
    jne .copyloop
    mov byte [ecx-1],10
    mov byte [ecx],0
    pop esi
    pop edx
    pop ebx
    ret

exit_prog:
    mov eax,1
    xor ebx,ebx
    int 0x80
