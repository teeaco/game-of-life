;format ELF64

include "logic.asm"

section '.data' writable
    grid db 0,0,0,0,0
         db 0,0,1,0,0
         db 0,0,0,1,0
         db 0,1,1,1,0
         db 0,0,0,0,0
    grid_size equ 5

    new_grid db grid_size*grid_size dup(0) 
    msg db "Generation: ", 0
    alive_cell db "1 ", 0
    dead_cell db "0 ", 0
    newline db 10, 0
    neighbor_count db '0', 0
    cell_buf db "Cell (0,0): Neighbors: 0", 10, 0

    birth_rule      db 3    ; Birth rule
    survive_min     db 2    ; Survival minimum
    survive_max     db 3    ; Survival maximum


    max_iterations db 6   ; Number of generations to simulate

section '.text' executable
public _start

_start:
    movzx r12, byte [max_iterations]  ; Correctly load byte into register
    call print_grid_with_generation

.main_loop:
    ; Process the grid
    mov esi, grid
    mov edi, new_grid
    mov ecx, grid_size
    call process_grid

    ; Copy new_grid back to grid
    mov ecx, grid_size * grid_size
    lea rsi, [new_grid]
    lea rdi, [grid]
    rep movsb

    ; Decrement counter and check
    dec r12
    jz .exit
    call print_grid_with_generation
    jmp .main_loop

.exit:
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; exit code 0
    syscall

print_grid_with_generation:
    push rax
    push rdi
    push rsi
    push rdx
    push r12
    
    ; Calculate generation number
    mov al, [max_iterations]
    sub al, r12b
    add al, '0'
    mov [msg+11], al    ; Update digit in message
    
    ; Print generation header
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg]
    mov rdx, 13        ; Length of "Generation: X" + newline
    syscall
    call new_line
    
    ; Print the grid
    call print_grid
    call new_line
    pop r12
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print_grid:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rsi, grid       ; Указатель на начало сетки
    mov rbx, grid_size  ; Счетчик строк
    
.row_loop:
    mov rcx, grid_size  ; Счетчик столбцов
    push rsi            ; Сохраняем начало строки
    
.col_loop:
    ; Загружаем значение клетки
    mov al, [rsi]
    
    ; Выбираем строку для вывода
    mov rdx, 2          ; Длина вывода (2 символа)
    lea rdi, [dead_cell] ; По умолчанию мертвая клетка
    test al, al
    jz .print
    lea rdi, [alive_cell] ; Живая клетка
    
.print:
    ; Выводим клетку
    push rcx
    push rsi
    mov rax, 1          ; sys_write
    mov rsi, rdi        ; Указатель на строку "0 " или "1 "
    mov rdi, 1          ; stdout
    syscall
    pop rsi
    pop rcx
    
    ; Переходим к следующей клетке
    inc rsi
    dec rcx
    jnz .col_loop
    
    ; Переход на новую строку
    push rsi
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    lea rsi, [newline]
    mov rdx, 1          ; Длина
    syscall
    pop rsi
    
    pop rsi             ; Восстанавливаем начало строки
    add rsi, grid_size  ; Переходим к следующей строке
    dec rbx
    jnz .row_loop
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


;---[count_neighbors]---
; Вход: ESI=grid, EAX=index, ECX=size
; Выход: EDX=кол-во живых соседей (0..8)
;---[count_neighbors]---
;---[count_neighbors]---
; Вход: ESI = grid, EAX = index, ECX = size (grid_size)
; Выход: DL = кол-во живых соседей (0..8)

;---[count_neighbors]---
; Вход: ESI=grid, EDI=index, ECX=size
; Выход: DL = кол-во живых соседей (0..8)
;---[count_neighbors]---
; Вход: ESI = grid, EDI = index, ECX = size
; Выход: DL = кол-во живых соседей (0..8)

count_neighbors:
    push rbx
    push r8
    push r9
    push r10
    push r11
    push r12

    xor dl, dl        ; Счётчик соседей

    mov ebx, edi      ; сохраняем index
    xor edx, edx
    mov eax, ebx
    div ecx           ; EAX = Y, EDX = X

    mov r11d, eax     ; Y
    mov r12d, edx     ; X

    ; Перебор всех соседей (dx=-1..1, dy=-1..1)
    mov r8d, -1       ; dy = -1
.dy_loop:
    mov r9d, -1       ; dx = -1
.dx_loop:
    ; Пропускаем центральную клетку
    test r8d, r8d
    jz .check_dx
    jmp .check_bounds

.check_dx:
    test r9d, r9d
    jz .skip

.check_bounds:
    ; Y + dy
    mov eax, r11d
    add eax, r8d
    cmp eax, 0
    jl .next_dx
    cmp eax, ecx
    jge .next_dx

    ; X + dx
    mov ebx, r12d
    add ebx, r9d
    cmp ebx, 0
    jl .next_dx
    cmp ebx, ecx
    jge .next_dx

    ; Индекс = (Y+dy)*size + (X+dx)
    imul eax, ecx
    add eax, ebx

    ; Защита от выхода за границы
    cmp eax, 0
    jl .next_dx
    cmp eax, grid_size*grid_size
    jge .next_dx

    ; Проверяем состояние соседа
    cmp byte [rsi + rax], 1
    jne .next_dx
    inc dl              ; Увеличиваем счётчик

.next_dx:
    inc r9d
    cmp r9d, 1
    jle .dx_loop

    inc r8d
    cmp r8d, 1
    jle .dy_loop

.done:
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbx
    ret

.skip:
    inc r9d
    jmp .dx_loop

    
;---[process_grid]---
; Вход: ESI=grid, EDI=new_grid, ECX=size
process_grid:
  push rbx
  push r12
  xor ebx, ebx            ; Индекс клетки (0..size*size-1)
.cell_loop:
  mov eax, ebx
  call count_neighbors    ; EDX = кол-во соседей
  mov al, [esi + ebx]    ; Текущее состояние
  call update_cell        ; AL = новое состояние
  mov [edi + ebx], al    ; Сохраняем в new_grid
  inc ebx
  cmp ebx, ecx
  jl .cell_loop
  pop r12
  pop rbx
  ret



;---[debug_print_neighbors]---
; Вход: DL = число соседей
;---[debug_print_neighbors]---
; DL = количество соседей
; R11D = Y
; R12D = X
;---[debug_print_neighbors]---
; DL = количество соседей
; R11D = Y
; R12D = X
debug_print_neighbors:
    push rax
    push rbx
    push rcx
    push rsi
    push rdi
    push rdx

    lea rsi, [cell_buf]

    ; Проверяем, что Y и X в пределах
    cmp r11b, 4
    ja .skip_log
    cmp r12b, 4
    ja .skip_log

    ; Cell (X,Y)
    mov al, r12b
    add al, '0'
    mov [rsi + 6], al   ; X

    mov al, r11b
    add al, '0'
    mov [rsi + 8], al   ; Y

    ; Neighbors: N
    xor eax, eax
    mov al, dl
    cmp al, 9
    ja .unknown
    add al, '0'
    jmp .write_neighbor

.unknown:
    mov al, '?'

.write_neighbor:
    mov [rsi + 19], al

    ; sys_write
    mov rax, 1
    mov rdi, 1
    lea rsi, [cell_buf]
    mov rdx, 22         ; длина строки "Cell (0,0): Neighbors: 0\n"
    syscall
    call new_line

.skip_log:
    pop rdx
    pop rdi
    pop rsi
    pop rcx
    pop rbx
    pop rax
    ret

;---[update_cell]---
; Вход: AL = текущее состояние (0 или 1)
;       DL = число живых соседей
; Выход: AL = новое состояние (0 или 1)
;---[update_cell]---
; Вход: AL = текущее состояние (0 или 1)
;       DL = число живых соседей
; Выход: AL = новое состояние (0 или 1)

update_cell:
    cmp al, 1
    je .check_survival

    ; Клетка мертва → проверяем рождение
    cmp dl, [birth_rule]
    mov al, 0
    je .alive
    jmp .done

.alive:
    mov al, 1
    jmp .done

.check_survival:
    ; Клетка жива → проверяем условия выживания
    cmp dl, [survive_min]
    jl .die
    cmp dl, [survive_max]
    jg .die
    mov al, 1
    jmp .done

.die:
    xor al, al

.done:
    ret