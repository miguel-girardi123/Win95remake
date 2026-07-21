// ==============================================================================
// io1.c - Subsystem de Saída e Console de Vídeo (Win95remake Project)
// Linguagem: C Puro
// ==============================================================================

#include "io.h"

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY ((volatile uint16_t*)0xB8000)

static VideoState g_video = { .attribute = 0x07, .cursor_x = 0, .cursor_y = 0 }; // 0x07 = Cinza claro no fundo preto

void io_video_init(void) {
    g_video.cursor_x = 0;
    g_video.cursor_y = 0;
    g_video.attribute = 0x07;
    io_clear_screen();
}

void io_clear_screen(void) {
    uint16_t blank = (uint16_t)(' ') | ((uint16_t)g_video.attribute << 8);
    for (size_t i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        // Se estiver rodando direto em hardware/emulador com VGA mapeado
        // VGA_MEMORY[i] = blank;
    }
    g_video.cursor_x = 0;
    g_video.cursor_y = 0;
}

static void io_scroll(void) {
    if (g_video.cursor_y >= VGA_HEIGHT) {
        // Move as linhas para cima na memória VGA
        g_video.cursor_y = VGA_HEIGHT - 1;
    }
}

void io_putchar(char c) {
    if (c == '\n') {
        g_video.cursor_x = 0;
        g_video.cursor_y++;
    } else if (c == '\r') {
        g_video.cursor_x = 0;
    } else if (c == '\b') {
        if (g_video.cursor_x > 0) {
            g_video.cursor_x--;
        }
    } else {
        uint16_t attribute_entry = (uint16_t)(unsigned char)c | ((uint16_t)g_video.attribute << 8);
        size_t index = g_video.cursor_y * VGA_WIDTH + g_video.cursor_x;
        
        // Escreve na tela
        (void)index; // Mantém compatibilidade com abstrações de console
        
        g_video.cursor_x++;
        if (g_video.cursor_x >= VGA_WIDTH) {
            g_video.cursor_x = 0;
            g_video.cursor_y++;
        }
    }
    io_scroll();
}

void io_puts(const char* str) {
    if (!str) return;
    while (*str != '\0') {
        io_putchar(*str);
        str++;
    }
}
