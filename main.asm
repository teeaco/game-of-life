format ELF64

include "logic.asm"

section '.data' writable
    grid db 0,0,0,0,0
         db 0,0,1,0,0
         db 0,0,0,1,0
         db 0,1,1,1,0
         db 0,0,0,0,0
    public grid
    grid_size = 5
    public grid_size

    new_grid db grid_size*grid_size dup(0) 
    msg db "Generation: ", 0

    alive_cell db "1 ", 0
    dead_cell db "0 ", 0
    newline db 10, 0
    neighbor_count db '0', 0

    birth_rule      db 3    ; Birth rule
    survive_min     db 2    ; Survival minimum
    survive_max     db 5    ; Survival maximum


    max_iterations db 2  ; Number of generations to simulate

section '.text' executable
public _start

_start:
    movzx r12, byte [max_iterations]  ; Correctly load byte into register
    ;call print_grid_with_generation
    .main_loop:
        call print_grid_with_generation

        ; Process the grid
        mov rsi, grid
        mov rdi, new_grid
        mov rcx, grid_size * grid_size ; <- Исправлено здесь
        call process_grid 

        ; Copy new_grid back to grid
        mov rcx, grid_size * grid_size
        lea rsi, [new_grid]
        lea rdi, [grid]
        rep movsb

        ; Decrement counter and check
        dec r12
        jz .exit
    jmp .main_loop
    .exit:
        mov rax, 60         ; sys_exit
        xor rdi, rdi        ; exit code 0
        syscall

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

