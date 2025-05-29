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


count_neighbors:
    push rcx
    push rdi
    push rdx
    push rbx
    push r8
    push r9
    push r10
    push r11
    push r12

    xor dl, dl        ; Счётчик соседей

    mov rbx, rdi      ; сохраняем index
    xor rdx, rdx
    mov rax, rbx
    mov ecx, grid_size
    div ecx           ; RAX = Y, RDX = X
    mov r11d, eax     ; Y
    mov r12d, edx     ; X

    ; DL = счётчик живых соседей
    xor dl, dl

    ; Сосед (x-1, y-1)
    mov eax, r12d      ; X
    add eax, -1
    mov ebx, r11d      ; Y
    add ebx, -1
    call check_bounds_and_alive

    ; Сосед (x, y-1)
    mov eax, r12d
    mov ebx, r11d
    add ebx, -1
    call check_bounds_and_alive

    ; Сосед (x+1, y-1)
    mov eax, r12d
    add eax, +1
    mov ebx, r11d
    add ebx, -1
    call check_bounds_and_alive

    ; Сосед (x-1, y)
    mov eax, r12d
    add eax, -1
    mov ebx, r11d
    call check_bounds_and_alive

    ; Сосед (x+1, y)
    mov eax, r12d
    add eax, +1
    mov ebx, r11d
    call check_bounds_and_alive

    ; Сосед (x-1, y+1)
    mov eax, r12d
    add eax, -1
    mov ebx, r11d
    add ebx, +1
    call check_bounds_and_alive

    ; Сосед (x, y+1)
    mov eax, r12d
    mov ebx, r11d
    add ebx, +1
    call check_bounds_and_alive

    ; Сосед (x+1, y+1)
    mov eax, r12d
    add eax, +1
    mov ebx, r11d
    add ebx, +1
    call check_bounds_and_alive

    mov rcx, grid_size * grid_size
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbx
    pop rdx
    pop rdi
    pop rcx
    ret



check_bounds_and_alive:
    push rax
    push rbx

    ; Проверяем x < 0 или x >= grid_size
    cmp eax, 0
    jl .skip
    cmp eax, grid_size - 1
    jg .skip

    ; Проверяем y < 0 или y >= grid_size
    cmp ebx, 0
    jl .skip
    cmp ebx, grid_size - 1
    jg .skip

    ; Индекс = y * grid_size + x
    mov ecx, grid_size
    imul ebx, ecx
    add ebx, eax
    cdqe
    cmp byte [rsi + rax], 1
    jne .skip
    inc dl   ; Увеличиваем счётчик живых соседей

    .skip:
    pop rbx
    pop rax
    ret