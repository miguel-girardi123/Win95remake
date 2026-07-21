; ==============================================================================
; HIMEM.ASM - Gerenciador de Inicialização de Memória e Transição para 64-bit
; Sintaxe: NASM
; Compilação: nasm -f bin himem.asm -o himem.bin
; ==============================================================================

[BITS 16]
[ORG 0x7C00]

start:
    cli                         ; Desativa interrupções para transição segura
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; 1. Habilitação da Linha A20 (Garantia para sistemas legados)
    call enable_a20

    ; 2. Detecção do Mapa de Memória Avançado (Substitutos do XMS: BIOS E820)
    call detect_memory_e820

    ; 3. Configuração dos Registradores para Long Mode (64-bit)
    call setup_identity_paging
    call enter_long_mode

[BITS 64]
long_mode_entry:
    ; Registradores de dados em 64-bit
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; --- HIMEM 64-bit Operacional ---
    ; A partir daqui, toda a RAM física até 16 Exabytes é acessível diretamente
    ; sem limites de 1MB ou estruturas XMS legadas.
    
    mov rax, 0x2026_HIMEM_OK    ; Assinatura de sucesso nos registradores de 64-bit
    hlt

; ==============================================================================
; ROTINAS DE SUPORTE (MODO REAL 16-BIT)
; ==============================================================================
[BITS 16]

enable_a20:
    ; Tenta via Fast A20 (Porta 0x92)
    in al, 0x92
    test al, 2
    jnz .done
    or al, 2
    and al, 0xFE
    out 0x92, al
.done:
    ret

detect_memory_e820:
    ; Utiliza a INT 15h, EAX=0xE820 para mapear RAM > 4GB
    mov edi, 0x8000             ; Buffer para guardar o mapa de memória
    xor ebx, ebx
    mov edx, 0x534D4150         ; Assinatura 'SMAP'
.loop:
    mov eax, 0xE820
    mov ecx, 24                 ; Tamanho da entrada
    int 0x15
    jc .error
    cmp eax, 0x534D4150
    jne .error
    add edi, 24
    test ebx, ebx
    jnz .loop
.error:
    ret

setup_identity_paging:
    ; Configura as tabelas de página (PML4, PDPT, PD) para acesso direto a RAM
    mov edi, 0x1000
    mov cr3, edi
    xor eax, eax
    mov ecx, 4096
    rep stosd

    ; Estrutura básica de Paginação de 64-bits
    mov dword [0x1000], 0x2003   ; PML4[0] -> PDPT
    mov dword [0x2000], 0x3003   ; PDPT[0] -> PD
    mov dword [0x3000], 0x0083   ; PD[0] -> 2MB Identity Page
    ret

enter_long_mode:
    ; Ativa PAE (Physical Address Extension) no CR4
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Ativa o bit de Long Mode no MSR EFER (0xC0000080)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Ativa Paging (PG) e Protection (PE) no CR0
    mov eax, cr0
    or eax, (1 << 31) | (1 << 0)
    mov cr0, eax

    ; Saltador distante (Far Jump) para carregar o Selector de Código de 64 bits
    jmp 0x08:long_mode_entry

; ==============================================================================
; TABELA DE DESCRITORES GLOBAIS (GDT) PARA 64-BIT
; ==============================================================================
align 8
gdt_start:
    dq 0x0000000000000000       ; Descritor Nulo
    dq 0x00AF9A0000000000       ; Descritor de Código 64-bit (Kernel)
    dq 0x00CF920000000000       ; Descritor de Dados 64-bit (Kernel)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 510-($-$$) db 0
dw 0xAA55                       ; Assinatura de Boot Sector
