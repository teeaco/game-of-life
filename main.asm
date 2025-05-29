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
    movzx r12, byte [max_iterations]  
    ;call print_grid_with_generation
    .main_loop:
        call print_grid_with_generation

        ; Process the grid
        mov rsi, grid
        mov rdi, new_grid
        mov rcx, grid_size * grid_size 
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
