format ELF64
extrn process_grid  ; Импорт функции из life_logic.asm

section '.data' writable
  ; Стартовый массив 5x5 (пример: глайдер)
  grid db 0,0,0,0,0
       db 0,0,1,0,0
       db 0,0,0,1,0
       db 0,1,1,1,0
       db 0,0,0,0,0
  grid_size equ 5   ; Размер поля
  iterations equ 10 ; Количество итераций

section '.text' executable
public _start

_start:
  mov ecx, iterations
.loop:
  ; Вызов функции обработки
  mov esi, grid
  mov ecx, grid_size
  call process_grid

  ; Запись состояния в файл (логирование)
  call write_grid_to_file

  dec ecx
  jnz .loop

  ; Завершение программы
  mov eax, 1
  xor ebx, ebx
  int 0x80

;---[write_grid_to_file]---
; Запись массива в файл grid.txt
write_grid_to_file:
  pusha
  ; ... (открытие файла, запись, закрытие) ...
  popa
  ret