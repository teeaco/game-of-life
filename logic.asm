format ELF64

section '.data' writable
  ; Константы для правил (можно менять)
  birth_rule      db 3    ; Клетка рождается при 3 соседях
  survive_min     db 2    ; Минимум соседей для выживания
  survive_max     db 3    ; Максимум соседей для выживания

section '.text' executable

;---[count_neighbors]---
; Подсчет живых соседей для клетки (X,Y)
; Вход:  ESI = адрес массива, EAX = X, EBX = Y, ECX = размер поля (N)
; Выход: EDX = количество живых соседей (0..8)
count_neighbors:
  xor edx, edx
  ; Проверка 8 соседей (края игнорируем)
  %macro check_neighbor 2
    mov edi, eax
    add edi, %1
    js %%skip
    cmp edi, ecx
    jge %%skip
    mov edi, ebx
    add edi, %2
    js %%skip
    cmp edi, ecx
    jge %%skip
    ; Расчет индекса: edi = (Y+%2)*size + (X+%1)
    imul edi, ecx
    add edi, eax
    add edi, %1
    add dl, [esi + edi]
  %%skip:
  %endmacro

  check_neighbor -1, -1
  check_neighbor 0, -1
  check_neighbor 1, -1
  check_neighbor -1, 0
  ; Текущая клетка (X,Y) пропускается
  check_neighbor 1, 0
  check_neighbor -1, 1
  check_neighbor 0, 1
  check_neighbor 1, 1
  ret


;---[update_cell]---
; Обновление состояния клетки по правилам
; Вход:  AL = текущее состояние, BL = число соседей
; Выход: AL = новое состояние (0 или 1)
update_cell:
  cmp al, 1
  je .check_survival
  ; Проверка рождения
  cmp bl, [birth_rule]
  sete al
  ret
.check_survival:
  cmp bl, [survive_min]
  jl .die
  cmp bl, [survive_max]
  jg .die
  mov al, 1
  ret
.die:
  mov al, 0
  ret

;---[process_grid]---
; Обработка всего массива
; Вход:  ESI = адрес массива, ECX = размер поля (N)
; Выход: Массив обновлен
process_grid:
  pusha
  mov edi, esi        ; Копия grid для записи
  xor eax, eax        ; X
  xor ebx, ebx        ; Y
.row_loop:
  call count_neighbors
  mov al, [esi + ebx*ecx + eax]  ; Текущее состояние
  call update_cell
  mov [edi + ebx*ecx + eax], al  ; Новое состояние
  inc eax
  cmp eax, ecx
  jl .row_loop
  xor eax, eax
  inc ebx
  cmp ebx, ecx
  jl .row_loop
  popa
  ret