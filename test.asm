format ELF64

section '.data' writable
    grid db 0,0,0,0,0
         db 0,0,1,0,0
         db 0,0,0,1,0
         db 0,1,1,1,0
         db 0,0,0,0,0
    public grid
    grid_size equ 5

    cell_buf db "Cell (x,y): Neighbors: ", '0', 20, 0
    newline db 10, 0
    msg db "work", 0xA, 0
    space db " ", 0
    digit_buffer rb 1

section '.text' executable
public _start

_start:
    lea rsi, [grid]
    xor rbx, rbx

.loop:
    cmp rbx, 25
    jge .done

    mov al, [rsi + rbx]

    ; Преобразуем в ASCII
    add al, '0'
    mov [digit_buffer], al

    ; Выводим цифру
    lea rsi, [digit_buffer]
    mov rdx, 1
    mov rax, 1
    mov rdi, 1
    syscall

    ; Выводим пробел
    lea rsi, [space]
    mov rdx, 1
    mov rax, 1
    mov rdi, 1
    syscall

    inc rbx
    jmp .loop

.done:
    ; Перевод строки
    lea rsi, [newline]
    mov rdx, 1
    mov rax, 1
    mov rdi, 1
    syscall

    ; Выход
    mov rax, 60
    xor rdi, rdi
    syscall



;---[new_line]---
; Выводит новую строку через sys_write
new_line:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret


print:
    ;инициализация регистров для вывода информации на экран
    mov rax, 4
    mov rbx, 1
    ;mov rcx, msg
    mov rdx, 14
    syscall

exit:
    mov rax, 1
    mov rbx, 0
    syscall



;---[print_int]---
; Вход: AL = число от 0 до 9
; Выход: выводит его через sys_write
print_int:
push rsi
push rdx
push rdi
.print_int_main:
    add al, '0'          ; преобразуем в ASCII
    mov [digit_buffer], al

    lea rsi, [digit_buffer]
    mov rdx, 1
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    syscall
pop rdi
pop rdx
pop rsi
    ret