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
    
    mov rsi, grid      ; Указатель на начало сетки
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
        cmp al, 0
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
        mov rax, rbx
        call count_neighbors    ; EDX = кол-во соседей
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

update_cell:
    cmp al, 1
    je .check_survival

    ; Клетка мертва → проверяем рождение
    cmp dl, [birth_rule]
    jne .stay_dead

    ; Рождение!
    mov al, 1
    jmp .done

    .stay_dead:
        xor al, al
        jmp .done


    .check_survival:
        ; Живая клетка → проверяем условия выживания
        cmp dl, [survive_min]
        jl .die
        cmp dl, [survive_max]
        jg .die
        ; В пределах → продолжает жить
        mov al, 1
        jmp .done

    .die:
        xor al, al   ; Умирает

    .done:
        ret