format ELF64

section '.data' writable
    grid db 0,0,0,0,0
         db 0,0,1,0,0
         db 0,0,0,1,0
         db 0,1,1,1,0
         db 0,0,0,0,0
    grid_size equ 5

    cell_buf db "Cell (x,y): Neighbors: ", '0', 20, 0
    newline db 10, 0

section '.text' executable
public _start

_start:
    ; Указатель на сетку
    mov rsi, grid   ; Адрес начала grid в .data

    ; Тестируем клетку index = 7 → координаты (2,1)
    mov edi, 7
    mov ecx, grid_size
    call count_neighbors

    ; Преобразуем DL в ASCII
    add dl, '0'
    mov [cell_buf + 18], dl

    ; Выводим строку
    lea rsi, [cell_buf]
    mov rdx, 22
    mov rax, 1
    mov rdi, 1
    syscall

    ; Новая строка
    call new_line

    ; Выход из программы
    xor rax, rax
    syscall


;---[count_neighbors]---
; Вход: ESI = указатель на grid
;       EDI = индекс клетки
;       ECX = размер сетки
; Выход: DL = число живых соседей
count_neighbors:
.count_neighbors_main:
    push rbx
    push r8
    push r9
    push r10
    push r11
    push r12

    xor dl, dl        ; Счётчик живых соседей

    ; Рассчитываем Y и X из index
    mov eax, edi      ; EDI = index
    xor edx, edx
    div ecx           ; EAX = Y, EDX = X
    mov r11d, eax     ; Сохраняем Y
    mov r12d, edx     ; Сохраняем X

    mov r8d, -1       ; dy ∈ [-1..+1]
.y_loop:
    mov r9d, -1       ; dx ∈ [-1..+1]
.x_loop:

    ; Пропускаем центральную клетку
    cmp r8d, 0
    jne .check_bounds
    cmp r9d, 0
    je .skip_center

.check_bounds:
    ; Проверяем Y + dy
    mov eax, r11d
    add eax, r8d
    cmp eax, 0
    jl .next_neighbor
    cmp eax, grid_size - 1
    jg .next_neighbor

    ; Проверяем X + dx
    mov eax, r12d
    add eax, r9d
    cmp eax, 0
    jl .next_neighbor
    cmp eax, grid_size - 1
    jg .next_neighbor

    ; Индекс = (Y + dy)*size + (X + dx)
    mov eax, r11d
    add eax, r8d
    imul eax, grid_size
    add eax, r12d
    add eax, r9d

    ; Проверяем выход за границы массива
    cmp eax, 0
    jl .next_neighbor
    cmp eax, 24
    jg .next_neighbor

    cdqe
    cmp byte [rsi + rax], 1
    jne .next_neighbor
    inc dl                ; Увеличиваем счётчик живых

.next_neighbor:
    inc r9d
    cmp r9d, 1
    jle .x_loop

    inc r8d
    cmp r8d, 1
    jle .y_loop

.done:
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbx
    ret

.skip_center:
    inc r9d
    cmp r9d, 1
    jle .x_loop

    inc r8d
    cmp r8d, 1
    jle .y_loop

    jmp .done


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