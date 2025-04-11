#include "xaxidma.h"
#include "xparameters.h"
#include "xil_cache.h"

// Adresses et tailles des buffers (à adapter selon votre design)
#define BUFFER_SIZE 1024
#define DDR_BASE_ADDR 0x00100000

// Instances DMA
XAxiDma axiDma;
volatile int transferDone = 0;

// Interruption callback (appelée quand un transfert est terminé)
void DmaCallback(XAxiDma* InstancePtr) {
    transferDone = 1;
}

int main() {
    // Initialisation DMA
    XAxiDma_Config *config = XAxiDma_LookupConfig(XPAR_AXIDMA_0_DEVICE_ID);
    XAxiDma_CfgInitialize(&axiDma, config);

    // Désactiver les interruptions pour simplifier (ou les configurer si besoin)
    XAxiDma_IntrDisable(&axiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrDisable(&axiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

    // Allouer des buffers en DDR (adresses alignées)
    u32 *i2sBuffer = (u32*)DDR_BASE_ADDR;
    u32 *fftBuffer = (u32*)(DDR_BASE_ADDR + BUFFER_SIZE * sizeof(u32));
    u32 *vgaBuffer = (u32*)(DDR_BASE_ADDR + 2 * BUFFER_SIZE * sizeof(u32));

    // ------------------------------------------------------------
    // Étape 1 : Transfert I2S -> DDR (S2MM)
    // ------------------------------------------------------------
    // 1. Écrire l'adresse de destination (DDR)
    Xil_Out32(0x40400000 + 0x48, 0x00100000);
    // 2. Écrire la taille du transfert
    Xil_Out32(0x40400000 + 0x58, 1024);
    // 3. Activer le DMA (bit 0 = start, bit 1 = interruption)
    Xil_Out32(0x40400000 + 0x30, 0x01);
    // 4. Attendre la fin du transfert (polling du bit IDLE)
    while (!(Xil_In32(0x40400000 + 0x30) & 0x02));

    // XAxiDma_SimpleTransfer(&axiDma, (u32)i2sBuffer, BUFFER_SIZE * sizeof(u32), XAXIDMA_DEVICE_TO_DMA);
    
    // Attendre la fin du transfert (polling)
    // while (!XAxiDma_IntrGetIrq(&axiDma, XAXIDMA_DEVICE_TO_DMA));

    // ------------------------------------------------------------
    // Étape 2 : Transfert DDR -> FFT (MM2S)
    // ------------------------------------------------------------
    XAxiDma_SimpleTransfer(&axiDma, (u32)fftBuffer, BUFFER_SIZE * sizeof(u32), XAXIDMA_DMA_TO_DEVICE);
    while (!XAxiDma_IntrGetIrq(&axiDma, XAXIDMA_DMA_TO_DEVICE));

    // ------------------------------------------------------------
    // Étape 3 : Transfert FFT -> DDR (S2MM)
    // ------------------------------------------------------------
    XAxiDma_SimpleTransfer(&axiDma, (u32)fftBuffer, BUFFER_SIZE * sizeof(u32), XAXIDMA_DEVICE_TO_DMA);
    while (!XAxiDma_IntrGetIrq(&axiDma, XAXIDMA_DEVICE_TO_DMA));

    // ------------------------------------------------------------
    // Étape 4 : Transfert DDR -> VGA (MM2S)
    // ------------------------------------------------------------
    XAxiDma_SimpleTransfer(&axiDma, (u32)vgaBuffer, BUFFER_SIZE * sizeof(u32), XAXIDMA_DMA_TO_DEVICE);
    while (!XAxiDma_IntrGetIrq(&axiDma, XAXIDMA_DMA_TO_DEVICE));

    return 0;
}