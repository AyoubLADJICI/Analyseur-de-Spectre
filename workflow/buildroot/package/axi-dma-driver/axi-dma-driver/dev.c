#include "dev.h"
#include <linux/delay.h>
static irqreturn_t irq_handler(int irq, void *data)
{
  u32 status;
  struct axi_dma_channel *chan;
  struct axi_dma_dev *dev;
  chan = data;
  dev = chan->parent;
  dev_info(&dev->pdev->dev, "IRQ!!\n");
  if(chan->direction == DMA_TO_DEVICE)
  {
    status = ioread32(dev->register_space + AXI_DMA_MM2S_DMASR);
    if(status & AXI_DMA_IOC)
      iowrite32(AXI_DMA_IOC, dev->register_space + AXI_DMA_MM2S_DMASR);
    if(status & AXI_DMA_IER)
    {
      dev_err(&dev->pdev->dev, "IRQ ERROR: status: 0x%x\n", status);
      iowrite32(AXI_DMA_IER, dev->register_space + AXI_DMA_MM2S_DMASR);
    }
  }else
  {
    status = ioread32(dev->register_space + AXI_DMA_S2MM_DMASR);
    if(status & AXI_DMA_IOC)
      iowrite32(AXI_DMA_IOC, dev->register_space + AXI_DMA_S2MM_DMASR);
    if(status & AXI_DMA_IER)
    {
      dev_err(&dev->pdev->dev, "IRQ ERROR: status: 0x%x\n", status);
      iowrite32(AXI_DMA_IER, dev->register_space + AXI_DMA_S2MM_DMASR);
    }
  }
  complete(&chan->completion);
  return 0;
}

int axi_dma_dev_init(struct axi_dma_dev *dev)
{
  int ret;
  ret = axi_dma_of_device(dev, irq_handler);
  if(ret < 0)
    return ret;
  if(dev->has_rx)
  {
    ret = axi_dma_channel_cdev_init(&dev->rx);
    if(ret < 0)
      goto release_of;
    iowrite32(AXI_DMA_RST, dev->register_space + AXI_DMA_S2MM_DMACR);
    msleep(1);
    init_completion(&dev->rx.completion);
  }
  if(dev->has_tx)
  {
    ret = axi_dma_channel_cdev_init(&dev->tx);
    if(ret < 0)
      goto release_rx_cdev;
    iowrite32(AXI_DMA_RST, dev->register_space + AXI_DMA_MM2S_DMACR);
    msleep(1);
    init_completion(&dev->tx.completion);
  }
  return 0;
release_rx_cdev:
  if(dev->has_rx)
    axi_dma_channel_cdev_release(&dev->rx);
release_of:
  axi_dma_of_release(dev);
  return ret;
}

void axi_dma_dev_release(struct axi_dma_dev *dev)
{
  if(dev->has_rx)
    axi_dma_channel_cdev_release(&dev->rx);
  if(dev->has_tx)
    axi_dma_channel_cdev_release(&dev->tx);
  axi_dma_of_release(dev);
}
