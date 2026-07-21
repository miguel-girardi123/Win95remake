; ==============================================================================
; cmd.asm - Recriação do COMMAND.COM em NASM x86_64 (Win95remake Project)
; Sintaxe: NASM (64-bit)
;
; Compilação (Linux/POSIX x86_64):
;   nasm -f elf64 cmd.asm -o cmd.o
;   ld cmd.o -o cmd.exe
; ==============================================================================

BITS 64

section .data
    ; Mensagens do sistema
    banner      db "Microsoft(R) Windows 95 Remake Shell [NASM x86_64]", 10
                db "(C)Copyright Microsoft Corp / Win95remake 1995-2026.", 10, 10, 0
    banner_len  equ $ - banner

    prompt      db "C:\WIN95> ", 0
    prompt_len  equ $ - prompt

    ver_msg     db 10, "Windows 95 Remake [Versao 4.00.950 - NASM x86_64]", 10, 10, 0
    ver_len     equ $ - ver_msg

    help_msg    db 10, "Comandos internos suportados:", 10
                db "  CLS     - Limpa a tela", 10
                db "  VER     - Exibe a versao do sistema", 10
                db "  ECHO    - Exibe mensagens na tela", 10
                db "  DIR     - Lista arquivos do diretorio", 10
                db "  HELP    - Exibe esta mensagem de ajuda", 10
                db "  EXIT    - Sai do interpretador de comandos", 10, 10, 0
    help_len    equ $ - help_msg

    dir_msg     db 10, " O volume na unidade C nao tem nome.", 10
                db " O Numero de Serie do Volume e 1995-2026", 10, 10
                db " Directory of C:\WIN95", 10, 10
                db "COMMAND  COM        95.120  24-08-95  09:50", 10
                db "HIMEM    SYS         9.310  24-08-95  09:50", 10
                db "IO       SYS       223.148  24-08-95  09:50", 10
                db "MSDOS    SYS             9  24-08-95  09:50", 10
                db "        4 file(s)        327.587 bytes", 10, 10, 0
    dir_len     equ $ - dir_msg

    bad_cmd     db "Comando ou nome de arquivo invalido.", 10, 0
    bad_len     equ $ - bad_cmd

    ; Sequência ANSI para limpar a tela
    cls_seq     db 27, "[2J", 27, "[H", 0
    cls_len     equ $ - cls_seq

    ; Comandos reconhecidos
    cmd_cls     db "CLS", 0
    cmd_ver     db "VER", 0
    cmd_exit    db "EXIT", 0
    cmd_help    db "HELP", 0
    cmd_dir     db "DIR", 0
    cmd_echo    db "ECHO", 0

section .bss
    buffer      resb 256
    cmd_part    resb 64
    arg_part    resb 192

section .text
    global _start

_start:
    ; Exibe o banner inicial
    mov rsi, banner
    mov rdx, banner_len
    call print_string

shell_loop:
    ; Exibe o prompt "C:\WIN95> "
    mov rsi, prompt
    mov rdx, prompt_len
    call print_string

    ; Leitura do teclado (sys_read)
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rsi, buffer
    mov rdx, 256
    syscall

    cmp rax, 1          ; Se pressionou apenas Enter, repete
    jle shell_loop

    ; Remove o \n do final e coloca \0
    mov byte [buffer + rax - 1], 0

    ; Converte o buffer de entrada para MAIÚSCULAS
    call to_uppercase

    ; Separa o comando dos argumentos
    call parse_input

    ; --- COMPARAÇÃO DE COMANDOS ---

    ; Check: EXIT
    mov rsi, cmd_part
    mov rdi, cmd_exit
    call strcmp
    jz exit_program

    ; Check: CLS
    mov rsi, cmd_part
    mov rdi, cmd_cls
    call strcmp
    jz do_cls

    ; Check: VER
    mov rsi, cmd_part
    mov rdi, cmd_ver
    call strcmp
    jz do_ver

    ; Check: HELP
    mov rsi, cmd_part
    mov rdi, cmd_help
    call strcmp
    jz do_help

    ; Check: DIR
    mov rsi, cmd_part
    mov rdi, cmd_dir
    call strcmp
    jz do_dir

    ; Check: ECHO
    mov rsi, cmd_part
    mov rdi, cmd_echo
    call strcmp
    jz do_echo

    ; Se não casou com nenhum comando interno
    mov rsi, bad_cmd
    mov rdx, bad_len
    call print_string
    jmp shell_loop

; ------------------------------------------------------------------------------
; ROTINAS DE EXECUÇÃO DOS COMANDOS
; ------------------------------------------------------------------------------

do_cls:
    mov rsi, cls_seq
    mov rdx, cls_len
    call print_string
    jmp shell_loop

do_ver:
    mov rsi, ver_msg
    mov rdx, ver_len
    call print_string
    jmp shell_loop

do_help:
    mov rsi, help_msg
    mov rdx, help_len
    call print_string
    jmp shell_loop

do_dir:
    mov rsi, dir_msg
    mov rdx, dir_len
    call print_string
    jmp shell_loop

do_echo:
    ; Imprime o texto do argumento que veio após o comando ECHO
    mov rsi, arg_part
    call strlen
    mov rdx, rax
    mov rsi, arg_part
    call print_string

    ; Imprime uma nova linha
    mov rsi, cls_seq + 3    ; Pega um \n se necessário ou usa código manual
    mov byte [buffer], 10
    mov byte [buffer+1], 0
    mov rsi, buffer
    mov rdx, 1
    call print_string

    jmp shell_loop

exit_program:
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; status 0
    syscall

; ------------------------------------------------------------------------------
; FUNÇÕES AUXILIARES DE STRING E I/O
; ------------------------------------------------------------------------------

print_string:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall
    ret

to_uppercase:
    mov rbx, buffer
.loop:
    mov al, [rbx]
    cmp al, 0
    je .done
    cmp al, 'a'
    jl .next
    cmp al, 'z'
    jg .next
    sub al, 32
    mov [rbx], al
.next:
    inc rbx
    jmp .loop
.done:
    ret

parse_input:
    mov rsi, buffer
    mov rdi, cmd_part
.copy_cmd:
    mov al, [rsi]
    cmp al, 0
    je .end_cmd
    cmp al, ' '
    je .found_space
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .copy_cmd
.found_space:
    mov byte [rdi], 0
    inc rsi
    ; Copia o resto para os argumentos
    mov rdi, arg_part
.copy_arg:
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .done
    inc rsi
    inc rdi
    jmp .copy_arg
.end_cmd:
    mov byte [rdi], 0
    mov byte [arg_part], 0
.done:
    ret

strcmp:
.loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    inc rsi
    inc rdi
    jmp .loop
.not_equal:
    mov rax, 1
    ret
.equal:
    xor rax, rax
    ret

strlen:
    xor rax, rax
.loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret
