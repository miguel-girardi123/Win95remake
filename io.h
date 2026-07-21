// ==============================================================================
// io.h - Definições e Protótipos de Entrada/Saída (Win95remake Project)
// ==============================================================================

#ifndef IO_H
#define IO_H

#include <stdint.h>
#include <stddef.h>

// --- Protótipos exportados pelo io3.asm ---
extern void asm_outb(uint16_t port, uint8_t value);
extern uint8_t asm_inb(uint16_t port);
extern void asm_io_wait(void);

// --- Estruturas de E/S ---
typedef struct {
    uint8_t attribute; // Cor e atributos de texto VGA
    uint8_t cursor_x;
    uint8_t cursor_y;
} VideoState;

// --- Protótipos do io1.c (Vídeo e Console) ---
void io_video_init(void);
void io_putchar(char c);
void io_puts(const char* str);
void io_clear_screen(void);

// --- Protótipos do io2.c (Teclado e Disco) ---
char io_getchar(void);
void io_readline(char* buffer, size_t max_len);
int io_disk_read_sector(uint32_t lba, uint8_t* buffer);

#endif // IO_H
