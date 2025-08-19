section .data
    welcomeMsg  db "=== Welcome to John's Simple Calculator ===",10,0
    promptNum1  db "Enter first number: ",0
    promptNum2  db "Enter second number: ",0
    promptOp    db "Choose operation (+, -, *, /, %): ",0
    resultMsg   db "Result: ",0
    errorDiv    db "Error: Cannot divide by zero!",10,0
    contMsg     db "Press Enter to continue or 'q' to quit: ",0
    newline     db 10,0

section .bss
    buf1    resb 16
    buf2    resb 16
    bufOp   resb 4
    bufCont resb 4
    num1    resd 1
    num2    resd 1
    result  resd 1
    outbuf  resb 16

section .text
    global _start

_start:
    ; print welcome only once
    mov eax,4
    mov ebx,1
    mov ecx,welcomeMsg
    mov edx,strlen welcomeMsg
    int 0x80

main_loop:
    ; ask for first number
    mov eax,4
    mov ebx,1
    mov ecx,promptNum1
    mov edx,strlen promptNum1
    int 0x80

    mov eax,3
    mov ebx,0
    mov ecx,buf1
    mov edx,16
    int 0x80
    call str2int
    mov [num1],eax

    ; ask for second number
    mov eax,4
    mov ebx,1
    mov ecx,promptNum2
    mov edx,strlen promptNum2
    int 0x80

    mov eax,3
    mov ebx,0
    mov ecx,buf2
    mov edx,16
    int 0x80
    call str2int
    mov [num2],eax

    ; ask for operator
    mov eax,4
    mov ebx,1
    mov ecx,promptOp
    mov edx,strlen promptOp
    int 0x80

    mov eax,3
    mov ebx,0
    mov ecx,bufOp
    mov edx,4
    int 0x80

    mov al,[bufOp]
    cmp al,'+'
    je do_add
    cmp al,'-'
    je do_sub
    cmp al,'*'
    je do_mul
    cmp al,'/'
    je do_div
    cmp al,'%'
    je do_mod
    jmp show_result   ; default fallthrough

do_add:
    mov eax,[num1]
    add eax,[num2]
    mov [result],eax
    jmp show_result

do_sub:
    mov eax,[num1]
    sub eax,[num2]
    mov [result],eax
    jmp show_result

do_mul:
    mov eax,[num1]
    imul eax,[num2]
    mov [result],eax
    jmp show_result

do_div:
    mov ebx,[num2]
    cmp ebx,0
    je div_error
    mov eax,[num1]
    xor edx,edx
    div ebx
    mov [result],eax
    jmp show_result

do_mod:
    mov ebx,[num2]
    cmp ebx,0
    je div_error
    mov eax,[num1]
    xor edx,edx
    div ebx
    mov [result],edx
    jmp show_result

div_error:
    mov eax,4
    mov ebx,1
    mov ecx,errorDiv
    mov edx,strlen errorDiv
    int 0x80
    jmp ask_continue

show_result:
    mov eax,4
    mov ebx,1
    mov ecx,resultMsg
    mov edx,strlen resultMsg
    int 0x80

    mov eax,[result]
    mov ecx,outbuf
    call int2str

    mov eax,4
    mov ebx,1
    mov ecx,outbuf
    mov edx,16
    int 0x80

ask_continue:
    mov eax,4
    mov ebx,1
    mov ecx,contMsg
    mov edx,strlen contMsg
    int 0x80

    mov eax,3
    mov ebx,0
    mov ecx,bufCont
    mov edx,4
    int 0x80

    cmp byte [bufCont],'q'
    je exit
    jmp main_loop

; ======================
; string to int
; input: ecx = buffer, eax=bytes read
; output: eax = integer
str2int:
    push ebx
    push edx
    xor eax,eax
    xor ebx,ebx
.next:
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
    jmp .next
.done:
    pop edx
    pop ebx
    ret

; int to string (eax → ecx buffer)
int2str:
    push ebx
    push edx
    push esi
    mov ebx,10
    mov esi,ecx
    add esi,12
    mov byte [esi],0
    dec esi
.loop:
    xor edx,edx
    div ebx
    add dl,'0'
    mov [esi],dl
    dec esi
    test eax,eax
    jnz .loop
    inc esi
    mov edi,ecx
.copy:
    mov al,[esi]
    mov [edi],al
    inc esi
    inc edi
    cmp al,0
    jne .copy
    mov byte [edi-1],10
    mov byte [edi],0
    pop esi
    pop edx
    pop ebx
    ret

; strlen macro-like routine
%macro strlen 1
    (%1 - $$) ; placeholder for size calculation
%endmacro

exit:
    mov eax,1
    xor ebx,ebx
    int 0x80
