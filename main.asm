format ELF64

include "logic.asm"

section '.bss' writable
    temp_char rb 1      ; Temporary buffer for keyboard input
    ;digit_buffer rb 2   ; Буфер для цифр
section '.data' writable
    grid db 0,0,0,0,0
         db 0,0,0,0,0
         db 0,0,0,0,0
         db 0,0,0,0,0
         db 0,0,0,0,0
    grid_size equ 5
    digit_buffer rb 2
    new_grid db grid_size*grid_size dup(0) 
    msg db "Generation: ", 0
    alive_cell db "1 ", 0
    dead_cell db "0 ", 0
    newline db 10, 0
    clear_screen db 27,"[H",27,"[2J",0 ; ANSI escape codes to clear screen
    press_space_msg db "Press ENTER to continue or Q to quit...", 10, 0
    ;cell_buf rb 1      ; Temporary buffer for keyboard input

    birth_rule      db 3    ; Birth rule
    survive_min     db 2   ; Survival minimum
    survive_max     db 4    ; Survival maximum

    ; Сообщения для ввода клеток
    cell_prompt db "Enter cell (x y, 0-4) or 'q' to finish:  ", 0
    invalid_input_msg db "Invalid input! Use format 'x y' (0-4) ", 10, 0
    clear_line db 27,"[A",27,"[K",0  ; ANSI: перемещение вверх + очистка строки 

    max_iterations db 11     ; Number of generations to simulate

section '.text' executable
public _start

_start:
    call input_initial_cells
    movzx r12, byte [max_iterations]  ; Load number of generations
    call clear_console
    call print_grid_with_generation

.main_loop:
    ; Wait for SPACE key press
    call wait_for_space
    
    ; Check if user wants to quit (Q pressed)
    cmp al, 'q'
    je .exit
    cmp al, 'Q'
    je .exit

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
    
    ; Clear console and print next generation
    call clear_console
    call print_grid_with_generation
    jmp .main_loop

.exit:
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; exit code 0
    syscall

; Ввод начальных клеток
input_initial_cells:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    .input_loop:
        ; Выводим приглашение
        mov rax, 1
        mov rdi, 1
        mov rsi, cell_prompt
        mov rdx, 40
        syscall

        ; Читаем ввод
        mov rax, 0
        mov rdi, 0
        mov rsi, temp_char
        mov rdx, 4
        syscall

        ; Проверяем на 'q'
        cmp byte [temp_char], 'q'
        je .done
        cmp byte [temp_char], 'Q'
        je .done

        ; Парсим координаты
        movzx ax, byte [temp_char]
        sub al, '0'
        cmp al, 0
        jl .invalid
        cmp al, grid_size-1
        jg .invalid

        movzx bx, byte [temp_char+2]
        sub bl, '0'
        cmp bl, 0
        jl .invalid
        cmp bl, grid_size-1
        jg .invalid

        ; Проверяем пробел между цифрами
        cmp byte [temp_char+1], ' '
        jne .invalid

        ; Вычисляем индекс
        imul ax, grid_size
        add al, bl
        movzx rsi, ax
        mov byte [grid + rsi], 1

        ; Очищаем строку с сообщением
        mov rax, 1
        mov rdi, 1
        ;mov rsi, clear_line
        mov rdx, 8
        syscall
        jmp .input_loop

    .invalid:
        ; Выводим сообщение об ошибке
        mov rax, 1
        mov rdi, 1
        mov rsi, invalid_input_msg
        mov rdx, 35
        syscall
        jmp .input_loop

    .done:
        ; Очищаем строку с сообщением
        mov rax, 1
        mov rdi, 1
        mov rsi, clear_line
        mov rdx, 8
        syscall
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret




; Clear console using ANSI escape codes
clear_console:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    lea rsi, [clear_screen]
    mov rdx, 7          ; Length of escape sequence
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Wait for SPACE key press
; Returns: AL = pressed key
wait_for_space:
    push rdi
    push rsi
    push rdx
    
    ; Print prompt message at the bottom
    mov rax, 1
    mov rdi, 1
    lea rsi, [press_space_msg]
    mov rdx, 38         ; Length of message
    syscall
    
    ; Read single character from stdin
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    lea rsi, [temp_char]
    mov rdx, 1          ; read 1 character
    syscall
    
    mov al, [temp_char]
    
    ; Clear the prompt message
    push rax
    mov rax, 1
    mov rdi, 1
    lea rsi, [clear_screen]
    mov rdx, 7
    syscall
    pop rax
    
    pop rdx
    pop rsi
    pop rdi
    ret

print_grid_with_generation:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r12

    ; Вычисляем номер поколения (0-99)
    movzx rax, byte [max_iterations]
    sub rax, r12

    ; Преобразуем число в две цифры
    mov rbx, 10
    xor rdx, rdx
    div rbx             ; rax = десятки, rdx = единицы

    ; Сохраняем цифры в буфер
    add al, '0'
    mov [digit_buffer], al
    add dl, '0'
    mov [digit_buffer+1], dl

    ; Копируем цифры в сообщение
    mov al, [digit_buffer]
    mov [msg+11], al    ; Десятки
    mov al, [digit_buffer+1]
    mov [msg+12], al    ; Единицы

    ; Выводим сообщение о поколении
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, 13         ; "Generation: XX" + нулевой байт
    syscall

    ; Выводим перевод строки
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Выводим само поле
    call print_grid

    pop r12
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


print_grid:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rsi, grid      ; Указатель на начало сетки
    mov rbx, grid_size  ; Счетчик строк
    
    .row_loop:
        mov rcx, grid_size  ; Счетчик столбцов
        push rsi           
        
    .col_loop:
        ; значение клетки
        mov al, [rsi]
        
        mov rdx, 2        
        lea rdi, [dead_cell] 
        cmp al, 0
        jz .print
        lea rdi, [alive_cell] 
        
    .print:
        push rcx
        push rsi
        mov rax, 1          
        mov rsi, rdi       
        mov rdi, 1       
        syscall
        pop rsi
        pop rcx
        
        ;  к следующей клетке
        inc rsi
        dec rcx
        jnz .col_loop
        
        ;  на новую строку
        push rsi
        mov rax, 1          
        mov rdi, 1          
        lea rsi, [newline]
        mov rdx, 1          
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

;---[process_grid]---
; Вход: rSI=grid, rDI=new_grid, rCX=size
process_grid:
  push rax
  push rcx
  push rbx
  push r12
  xor rbx, rbx            ; Индекс клетки (0..size*size-1)
  mov rcx, grid_size * grid_size
    .cell_loop:
        ; Сохраняем указатели и индекс
        push rsi
        push rdi
        push rbx

        ; Подсчёт соседей для текущей клетки
        mov rdi, rbx        ; Передаем индекс в RDI
        call count_neighbors ; Результат в DL

        ; В process_grid после call count_neighbors:




        ; Восстанавливаем указатель на исходную сетку
        pop rbx
        pop rdi
        pop rsi

        ; Получаем текущее состояние и обновляем
        mov al, [rsi + rbx]    ; Текущее состояние
        call update_cell        ; AL = новое состояние
        mov [rdi + rbx], al    ; Сохраняем в new_grid

        inc rbx
        cmp rbx, rcx
    jne .cell_loop
        pop r12
        pop rbx
        pop rcx
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
    je .alive_cell

    ; Мертвая клетка - проверяем рождение
    cmp dl, [birth_rule]
    je .make_alive
    xor al, al          ; остается мертвой
    ret

.alive_cell:
    ; Живая клетка - проверяем выживание
    cmp dl, [survive_min]
    jl .make_dead
    cmp dl, [survive_max]
    jg .make_dead
    mov al, 1           ; остается живой
    ret

.make_alive:
    mov al, 1
    ret

.make_dead:
    xor al, al
    ret



;---[count_neighbors]---
; Вход: RSI = указатель на grid, RDI = индекс клетки
; Выход: DL = количество живых соседей (0-8)
count_neighbors:
    push rbx
    push rcx
    push r8
    push r9
    push r10
    push r11
    push rsi       ; Важно сохранить указатель на grid!

    ; Преобразуем индекс в координаты (x,y)
    mov rax, rdi    ; index
    xor rdx, rdx
    mov rbx, grid_size
    div rbx         ; rax = y, rdx = x
    mov r8, rax     ; сохраняем y
    mov r9, rdx     ; сохраняем x

    xor r10, r10    ; обнуляем счетчик соседей

    ; Проверяем всех 8 соседей
    mov r11, -1     ; dy = -1
.y_loop:
    mov rcx, -1     ; dx = -1
.x_loop:
    ; Пропускаем центральную клетку (dx=0, dy=0)
    test r11, r11
    jnz .check_neighbor
    test rcx, rcx
    jz .skip_neighbor

.check_neighbor:
    ; Вычисляем координаты соседа
    mov rax, r8     ; y
    add rax, r11    ; y + dy
    cmp rax, 0
    jl .skip_neighbor   ; если y < 0
    cmp rax, grid_size-1
    jg .skip_neighbor   ; если y >= grid_size

    mov rbx, r9     ; x
    add rbx, rcx    ; x + dx
    cmp rbx, 0
    jl .skip_neighbor   ; если x < 0
    cmp rbx, grid_size-1
    jg .skip_neighbor   ; если x >= grid_size

    ; Вычисляем индекс соседа
    imul rax, grid_size
    add rax, rbx

    ; Проверяем состояние клетки
    cmp byte [rsi + rax], 1
    jne .skip_neighbor
    inc r10         ; увеличиваем счетчик живых соседей

.skip_neighbor:
    inc rcx         ; увеличиваем dx
    cmp rcx, 1
    jle .x_loop     ; dx <= 1

    inc r11         ; увеличиваем dy
    cmp r11, 1
    jle .y_loop     ; dy <= 1

    ; Возвращаем результат в dl
    mov dl, r10b

    pop rsi         ; Восстанавливаем указатель на grid
    pop r11
    pop r10
    pop r9
    pop r8
    pop rcx
    pop rbx
    ret

