
new_line:
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    mov rax, 0xA
    push rax
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    mov rax, 1
    syscall
    pop rax
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret


;---[print_grid]---
; Вход: RSI = адрес grid
;       RBX = grid_size = 5
; Выводит сетку 5x5 в терминал, разделяя строки \n
