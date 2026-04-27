/*
 * scsi.h -- NCR 5380 (AMD AM5380) SCSI controller emulation
 *
 * Emulates the 8-register NCR 5380 interface with bus phase state machine.
 * Supports INQUIRY, TEST UNIT READY, READ CAPACITY, MODE SENSE,
 * MODE SELECT, START/STOP UNIT, REQUEST SENSE, READ(6), READ(10), WRITE(6).
 *
 * Designed for the Agfa 9000PS where the AM5380 is at 0x05000000
 * with stride-1 (contiguous byte addresses 0x05000000-0x05000007).
 * Verified by Adrian Black on real hardware (2026-03-27).
 */
#ifndef SCSI_H
#define SCSI_H

#include <stdint.h>

/* SCSI bus phases */
#define SCSI_PHASE_FREE         0
#define SCSI_PHASE_ARBITRATION  1
#define SCSI_PHASE_SELECTION    2
#define SCSI_PHASE_COMMAND      3
#define SCSI_PHASE_DATA_IN      4
#define SCSI_PHASE_DATA_OUT     5
#define SCSI_PHASE_STATUS       6
#define SCSI_PHASE_MSG_IN       7
#define SCSI_PHASE_MSG_OUT      8

/* NCR 5380 register indices */
#define NCR_REG_DATA        0   /* Current SCSI Data / Output Data */
#define NCR_REG_ICR         1   /* Initiator Command Register */
#define NCR_REG_MODE        2   /* Mode Register */
#define NCR_REG_TCR         3   /* Target Command Register */
#define NCR_REG_CSBS        4   /* Current SCSI Bus Status (read) */
#define NCR_REG_BSR         5   /* Bus and Status Register (read) */
#define NCR_REG_IDATA       6   /* Input Data Register (read) */
#define NCR_REG_RESET       7   /* Reset Parity/Interrupts (read) */

/* ICR bits */
#define ICR_DATA_BUS        0x01
#define ICR_ATN             0x02
#define ICR_SEL             0x04
#define ICR_BSY             0x08
#define ICR_ACK             0x10
#define ICR_AIP             0x40  /* Arbitration In Progress (read) */
#define ICR_RST             0x80  /* Assert RST */

/* Mode register bits */
#define MODE_ARBITRATE      0x01
#define MODE_DMA            0x02
#define MODE_MONITOR_BSY    0x04
#define MODE_EOP_INT        0x08
#define MODE_PARITY_INT     0x10
#define MODE_PARITY_CHK     0x20
#define MODE_TARGET         0x40
#define MODE_BLOCK_DMA      0x80

/* Bus Status register bits (read from reg 4) */
#define BST_DBP             0x01  /* Data Bus Parity */
#define BST_SEL             0x02
#define BST_IO              0x04
#define BST_CD              0x08
#define BST_MSG             0x10
#define BST_REQ             0x20
#define BST_BSY             0x40
#define BST_RST             0x80

/* Bus and Status register bits (read from reg 5) */
#define BAS_ACK             0x01
#define BAS_ATN             0x02
#define BAS_BUSY_ERR        0x04
#define BAS_PHASE_MATCH     0x08
#define BAS_IRQ             0x10
#define BAS_PARITY_ERR      0x20
#define BAS_DMA_REQ         0x40
#define BAS_END_DMA         0x80

/* SCSI device (disk image) */
typedef struct scsi_device {
    int present;
    FILE *image;            /* Disk image file handle */
    uint32_t blocks;        /* Total blocks */
    uint32_t block_size;    /* Bytes per block (512 or 1024) */
    uint8_t sense_key;      /* Last error sense key */
    uint8_t sense_asc;      /* Additional sense code */
} scsi_device_t;

/* NCR 5380 state */
typedef struct ncr5380 {
    uint8_t regs[8];        /* Register file */
    uint8_t output_data;    /* Data bus output latch */
    int phase;              /* Current bus phase */
    int selected_id;        /* Currently selected SCSI ID (-1=none) */

    /* Command buffer */
    uint8_t cmd[16];
    int cmd_len;
    int cmd_pos;

    /* Data transfer buffer */
    uint8_t *data_buf;
    int data_len;
    int data_pos;
    int data_dir;           /* 0=none, 1=to host (DATA_IN), 2=from host (DATA_OUT) */

    /* Status/message */
    uint8_t status_byte;
    uint8_t msg_byte;

    /* DMA state */
    int dma_active;

    /* Devices */
    scsi_device_t devices[8];

    /* IRQ callback */
    void (*irq_callback)(int level, void *ctx);
    void *irq_ctx;
} ncr5380_t;

/* Initialize */
void ncr5380_init(ncr5380_t *ncr);

/* Reset */
void ncr5380_reset(ncr5380_t *ncr);

/* Register access (reg 0-7) */
uint8_t ncr5380_read(ncr5380_t *ncr, int reg);
void ncr5380_write(ncr5380_t *ncr, int reg, uint8_t val);

/* Pseudo-DMA data port */
uint8_t ncr5380_dma_read(ncr5380_t *ncr);
void ncr5380_dma_write(ncr5380_t *ncr, uint8_t val);

/* Attach a disk image at a given SCSI ID */
int ncr5380_attach_image(ncr5380_t *ncr, int id, const char *path, int block_size);

/* Periodic tick */
void ncr5380_tick(ncr5380_t *ncr);

#endif
