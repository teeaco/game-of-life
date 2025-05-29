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
    mov rdx, 13        
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

    ; Клетка мертва проверяем рождение
    cmp dl, [birth_rule]
    jne .stay_dead

    ; Рождение!
    mov al, 1
    jmp .done

    .stay_dead:
        xor al, al
        jmp .done


    .check_survival:
        ; Живая клетка проверяем условия выживания
        cmp dl, [survive_min]
        jl .die
        cmp dl, [survive_max]
        jg .die
        ; В пределах продолжает жить
        mov al, 1
        jmp .done

    .die:
        xor al, al   ; Умирает

    .done:
        ret




;---[count_neighbors]---
; Вход: ESI = grid, EDI = index, ECX = size
; Выход: DL = кол-во живых соседей (0..8)

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

    mov rbx, rdi      ;  index
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
    inc dl   ; счётчик живых соседей

    .skip:
    pop rbx
    pop rax
    ret



