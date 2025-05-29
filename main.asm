format ELF64

include "logic.asm"

section '.bss' writable
    temp_char rb 1      ; Temporary buffer for keyboard input

section '.data' writable
    grid db 1,1,0,1,0
         db 1,0,1,0,0
         db 0,0,0,1,0
         db 0,1,1,1,0
         db 0,0,1,0,0
    grid_size equ 5

    new_grid db grid_size*grid_size dup(0) 
    msg db "Generation: ", 0
    alive_cell db "1 ", 0
    dead_cell db "0 ", 0
    newline db 10, 0
    clear_screen db 27,"[H",27,"[2J",0 ; ANSI escape codes to clear screen
    press_space_msg db "Press ENTER to continue or Q to quit...", 10, 0
    cell_buf rb 1      ; Temporary buffer for keyboard input
    zero db 0


    birth_rule      db 3    ; Birth rule
    survive_min     db 2   ; Survival minimum
    survive_max     db 4    ; Survival maximum

    max_iterations db 6     ; Number of generations to simulate

section '.text' executable
public _start

_start:
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
