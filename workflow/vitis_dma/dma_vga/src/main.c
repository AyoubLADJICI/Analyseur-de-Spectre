#include "xil_io.h"
#include "xparameters.h"

#define DMA_BASE_ADDR      XPAR_AXI_DMA_0_BASEADDR  // ou _2 selon ton IP
#define DMA_MM2S_DMACR     (DMA_BASE_ADDR + 0x00)
#define DMA_MM2S_DMASR     (DMA_BASE_ADDR + 0x04)
#define DMA_MM2S_SA        (DMA_BASE_ADDR + 0x18)
#define DMA_MM2S_LENGTH    (DMA_BASE_ADDR + 0x28)

#define DDR_BASE_ADDR      0x10000000
#define FRAME_WIDTH        640
#define FRAME_HEIGHT       480

int main() {
    u32 *frame_ptr = (u32 *) DDR_BASE_ADDR;

    // 1. Écrire une image en mémoire
    for (int y = 0; y < FRAME_HEIGHT; y++) {
        for (int x = 0; x < FRAME_WIDTH; x++) {
            *frame_ptr++ = 0x0000F00F;  // violet
        }
    }

    // 2. Lancer le DMA
    u32 frame_size = FRAME_WIDTH * FRAME_HEIGHT * 4; // 4 octets/pixel

    // a. Reset DMA
    Xil_Out32(DMA_MM2S_DMACR, 0x4);  // reset
    Xil_Out32(DMA_MM2S_DMACR, 0x1);  // enable

    // b. Spécifie l’adresse source
    Xil_Out32(DMA_MM2S_SA, DDR_BASE_ADDR);

    // c. Spécifie la longueur du transfert
    Xil_Out32(DMA_MM2S_LENGTH, frame_size);

    // Boucle d’attente simple (optionnel)
    while ((Xil_In32(DMA_MM2S_DMASR) & 0x1000) == 0);  // wait for DMA idle

    return 0;
}
