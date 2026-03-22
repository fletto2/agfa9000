/*
 * scsi.c -- NCR 5380 (AMD AM5380) SCSI controller emulation
 *
 * Implements the full 8-register NCR 5380 interface with SCSI bus
 * phase state machine. Handles the initiator mode operations used
 * by the Agfa 9000PS firmware.
 *
 * Reference: NCR 5380 datasheet, Hatari ncr5380.c, Agfa ROM analysis
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "scsi.h"

/* Forward declarations */
static int cmd_length(uint8_t opcode);

/* ---- Internal helpers ---- */

static scsi_device_t *get_target(ncr5380_t *ncr)
{
    if (ncr->selected_id < 0 || ncr->selected_id > 7)
        return NULL;
    scsi_device_t *dev = &ncr->devices[ncr->selected_id];
    return dev->present ? dev : NULL;
}

static void set_phase(ncr5380_t *ncr, int phase)
{
    ncr->phase = phase;
}

/* Build a standard INQUIRY response */
static int handle_inquiry(scsi_device_t *dev, uint8_t *buf, int alloc_len)
{
    memset(buf, 0, alloc_len < 36 ? alloc_len : 36);
    buf[0] = 0x00;  /* Direct-access device */
    buf[1] = 0x00;  /* Not removable */
    buf[2] = 0x01;  /* SCSI-1 */
    buf[3] = 0x01;  /* Response data format */
    buf[4] = 31;    /* Additional length */
    /* Vendor (bytes 8-15) */
    memcpy(buf + 8,  "QUANTUM ", 8);
    /* Product (bytes 16-31) */
    memcpy(buf + 16, "P40S            ", 16);
    /* Revision (bytes 32-35) */
    memcpy(buf + 32, "1.0 ", 4);
    return alloc_len < 36 ? alloc_len : 36;
}

/* Handle a SCSI command */
static void execute_command(ncr5380_t *ncr)
{
    scsi_device_t *dev = get_target(ncr);
    uint8_t cmd = ncr->cmd[0];
    uint32_t lba;
    uint16_t count;
    int len;

    if (!dev) {
        ncr->status_byte = 0x02;  /* Check Condition */
        set_phase(ncr, SCSI_PHASE_STATUS);
        return;
    }

    /* Clear sense on new command */
    dev->sense_key = 0;
    dev->sense_asc = 0;

    {
        extern int verbose;
        fprintf(stderr, "[SCSI] Command 0x%02X to ID %d (len=%d)\n", cmd, ncr->selected_id, cmd_length(cmd));
    }

    switch (cmd) {
    case 0x00:  /* TEST UNIT READY */
        ncr->status_byte = 0x00;  /* Good */
        ncr->data_len = 0;
        set_phase(ncr, SCSI_PHASE_STATUS);
        break;

    case 0x03:  /* REQUEST SENSE */
        len = ncr->cmd[4];
        if (len == 0) len = 4;
        if (len > 18) len = 18;
        if (!ncr->data_buf) ncr->data_buf = malloc(256);
        memset(ncr->data_buf, 0, len);
        ncr->data_buf[0] = 0x70;  /* Current errors */
        ncr->data_buf[2] = dev->sense_key;
        ncr->data_buf[7] = 10;    /* Additional length */
        ncr->data_buf[12] = dev->sense_asc;
        ncr->data_len = len;
        ncr->data_pos = 0;
        ncr->data_dir = 1;  /* DATA_IN */
        set_phase(ncr, SCSI_PHASE_DATA_IN);
        ncr->status_byte = 0x00;
        break;

    case 0x08:  /* READ(6) */
        lba = ((ncr->cmd[1] & 0x1F) << 16) | (ncr->cmd[2] << 8) | ncr->cmd[3];
        count = ncr->cmd[4];
        if (count == 0) count = 256;
        len = count * dev->block_size;
        if (!ncr->data_buf) ncr->data_buf = malloc(256 * 1024);
        if (dev->image && lba + count <= dev->blocks) {
            fseek(dev->image, (long)lba * dev->block_size, SEEK_SET);
            fread(ncr->data_buf, 1, len, dev->image);
            ncr->status_byte = 0x00;
        } else {
            memset(ncr->data_buf, 0, len);
            dev->sense_key = 0x05;  /* Illegal Request */
            ncr->status_byte = 0x02;
        }
        ncr->data_len = len;
        ncr->data_pos = 0;
        ncr->data_dir = 1;
        set_phase(ncr, SCSI_PHASE_DATA_IN);
        break;

    case 0x0A:  /* WRITE(6) */
        lba = ((ncr->cmd[1] & 0x1F) << 16) | (ncr->cmd[2] << 8) | ncr->cmd[3];
        count = ncr->cmd[4];
        if (count == 0) count = 256;
        len = count * dev->block_size;
        if (!ncr->data_buf) ncr->data_buf = malloc(256 * 1024);
        ncr->data_len = len;
        ncr->data_pos = 0;
        ncr->data_dir = 2;  /* DATA_OUT */
        ncr->status_byte = 0x00;
        set_phase(ncr, SCSI_PHASE_DATA_OUT);
        break;

    case 0x12:  /* INQUIRY */
        len = ncr->cmd[4];
        if (len == 0) len = 36;
        if (!ncr->data_buf) ncr->data_buf = malloc(256);
        len = handle_inquiry(dev, ncr->data_buf, len);
        ncr->data_len = len;
        ncr->data_pos = 0;
        ncr->data_dir = 1;
        set_phase(ncr, SCSI_PHASE_DATA_IN);
        ncr->status_byte = 0x00;
        break;

    case 0x15:  /* MODE SELECT(6) */
        /* Accept and ignore mode select data */
        len = ncr->cmd[4];
        if (len > 0) {
            if (!ncr->data_buf) ncr->data_buf = malloc(256);
            ncr->data_len = len;
            ncr->data_pos = 0;
            ncr->data_dir = 2;  /* DATA_OUT */
            set_phase(ncr, SCSI_PHASE_DATA_OUT);
        }
        ncr->status_byte = 0x00;
        if (len == 0) set_phase(ncr, SCSI_PHASE_STATUS);
        break;

    case 0x1B:  /* START/STOP UNIT */
        ncr->status_byte = 0x00;  /* Good */
        ncr->data_len = 0;
        set_phase(ncr, SCSI_PHASE_STATUS);
        break;

    case 0x1A:  /* MODE SENSE(6) */
        len = ncr->cmd[4];
        if (len == 0) len = 4;
        if (!ncr->data_buf) ncr->data_buf = malloc(256);
        memset(ncr->data_buf, 0, len);
        ncr->data_buf[0] = len - 1;  /* Mode data length */
        ncr->data_buf[1] = 0x00;     /* Medium type */
        ncr->data_buf[2] = 0x00;     /* Device-specific parameter */
        ncr->data_buf[3] = 0x00;     /* Block descriptor length */
        ncr->data_len = len;
        ncr->data_pos = 0;
        ncr->data_dir = 1;
        set_phase(ncr, SCSI_PHASE_DATA_IN);
        ncr->status_byte = 0x00;
        break;

    case 0x25:  /* READ CAPACITY(10) */
        if (!ncr->data_buf) ncr->data_buf = malloc(256);
        {
            uint32_t last_block = dev->blocks - 1;
            uint32_t bs = dev->block_size;
            ncr->data_buf[0] = (last_block >> 24) & 0xFF;
            ncr->data_buf[1] = (last_block >> 16) & 0xFF;
            ncr->data_buf[2] = (last_block >> 8) & 0xFF;
            ncr->data_buf[3] = last_block & 0xFF;
            ncr->data_buf[4] = (bs >> 24) & 0xFF;
            ncr->data_buf[5] = (bs >> 16) & 0xFF;
            ncr->data_buf[6] = (bs >> 8) & 0xFF;
            ncr->data_buf[7] = bs & 0xFF;
        }
        ncr->data_len = 8;
        ncr->data_pos = 0;
        ncr->data_dir = 1;
        set_phase(ncr, SCSI_PHASE_DATA_IN);
        ncr->status_byte = 0x00;
        break;

    case 0x28:  /* READ(10) */
        lba = (ncr->cmd[2] << 24) | (ncr->cmd[3] << 16)
            | (ncr->cmd[4] << 8) | ncr->cmd[5];
        count = (ncr->cmd[7] << 8) | ncr->cmd[8];
        len = count * dev->block_size;
        if (!ncr->data_buf) ncr->data_buf = malloc(256 * 1024);
        if (dev->image && lba + count <= dev->blocks) {
            fseek(dev->image, (long)lba * dev->block_size, SEEK_SET);
            fread(ncr->data_buf, 1, len, dev->image);
            ncr->status_byte = 0x00;
        } else {
            memset(ncr->data_buf, 0, len);
            dev->sense_key = 0x05;
            ncr->status_byte = 0x02;
        }
        ncr->data_len = len;
        ncr->data_pos = 0;
        ncr->data_dir = 1;
        set_phase(ncr, SCSI_PHASE_DATA_IN);
        break;

    default:
        fprintf(stderr, "[SCSI] Unknown command 0x%02X\n", cmd);
        dev->sense_key = 0x05;  /* Illegal Request */
        dev->sense_asc = 0x20;  /* Invalid command */
        ncr->status_byte = 0x02;
        ncr->data_len = 0;
        set_phase(ncr, SCSI_PHASE_STATUS);
        break;
    }
}

/* Determine expected command length from opcode */
static int cmd_length(uint8_t opcode)
{
    switch (opcode >> 5) {
    case 0: return 6;   /* Group 0 */
    case 1: return 10;  /* Group 1 */
    case 2: return 10;  /* Group 2 */
    case 5: return 12;  /* Group 5 */
    default: return 6;
    }
}

/* ---- Public API ---- */

void ncr5380_init(ncr5380_t *ncr)
{
    memset(ncr, 0, sizeof(*ncr));
    ncr->selected_id = -1;
    ncr->phase = SCSI_PHASE_FREE;
}

void ncr5380_reset(ncr5380_t *ncr)
{
    memset(ncr->regs, 0, sizeof(ncr->regs));
    ncr->output_data = 0;
    ncr->phase = SCSI_PHASE_FREE;
    ncr->selected_id = -1;
    ncr->cmd_pos = 0;
    ncr->cmd_len = 0;
    ncr->data_pos = 0;
    ncr->data_len = 0;
    ncr->data_dir = 0;
    ncr->dma_active = 0;
    ncr->status_byte = 0;
    ncr->msg_byte = 0;
}

uint8_t ncr5380_read(ncr5380_t *ncr, int reg)
{
    switch (reg) {
    case NCR_REG_DATA:  /* Reg 0: Current SCSI Data */
        if (ncr->phase == SCSI_PHASE_DATA_IN && ncr->data_pos < ncr->data_len)
            return ncr->data_buf[ncr->data_pos];
        if (ncr->phase == SCSI_PHASE_STATUS)
            return ncr->status_byte;
        if (ncr->phase == SCSI_PHASE_MSG_IN)
            return ncr->msg_byte;
        return ncr->output_data;

    case NCR_REG_ICR:  /* Reg 1: Initiator Command */
        return ncr->regs[NCR_REG_ICR] & 0x1F;  /* Mask out read-only bits */

    case NCR_REG_MODE:  /* Reg 2: Mode */
        return ncr->regs[NCR_REG_MODE];

    case NCR_REG_TCR:  /* Reg 3: Target Command */
        return ncr->regs[NCR_REG_TCR];

    case NCR_REG_CSBS: {  /* Reg 4: Current SCSI Bus Status */
        uint8_t val = 0;
        if (ncr->phase != SCSI_PHASE_FREE && ncr->selected_id >= 0)
            val |= BST_BSY;
        /* Set phase bits based on current phase */
        switch (ncr->phase) {
        case SCSI_PHASE_DATA_OUT:   break;  /* IO=0 CD=0 MSG=0 */
        case SCSI_PHASE_DATA_IN:    val |= BST_IO; break;
        case SCSI_PHASE_COMMAND:    val |= BST_CD; break;
        case SCSI_PHASE_STATUS:     val |= BST_IO | BST_CD; break;
        case SCSI_PHASE_MSG_OUT:    val |= BST_CD | BST_MSG; break;
        case SCSI_PHASE_MSG_IN:     val |= BST_IO | BST_CD | BST_MSG; break;
        }
        /* REQ: assert when target has data ready */
        if (ncr->phase == SCSI_PHASE_COMMAND)
            val |= BST_REQ;  /* Target requests command bytes */
        if (ncr->phase == SCSI_PHASE_DATA_IN && ncr->data_pos < ncr->data_len)
            val |= BST_REQ;
        if (ncr->phase == SCSI_PHASE_DATA_OUT && ncr->data_pos < ncr->data_len)
            val |= BST_REQ;
        if (ncr->phase == SCSI_PHASE_STATUS)
            val |= BST_REQ;
        if (ncr->phase == SCSI_PHASE_MSG_IN)
            val |= BST_REQ;
        return val;
    }

    case NCR_REG_BSR: {  /* Reg 5: Bus and Status */
        uint8_t val = 0;
        /* Phase match: TCR phase matches actual bus phase */
        {
            uint8_t tcr_phase = ncr->regs[NCR_REG_TCR] & 0x07;
            uint8_t bus_phase = 0;
            switch (ncr->phase) {
            case SCSI_PHASE_DATA_OUT:  bus_phase = 0; break;
            case SCSI_PHASE_DATA_IN:   bus_phase = 1; break;
            case SCSI_PHASE_COMMAND:   bus_phase = 2; break;
            case SCSI_PHASE_STATUS:    bus_phase = 3; break;
            case SCSI_PHASE_MSG_OUT:   bus_phase = 6; break;
            case SCSI_PHASE_MSG_IN:    bus_phase = 7; break;
            default: bus_phase = 0; break;
            }
            if (tcr_phase == bus_phase)
                val |= BAS_PHASE_MATCH;
        }
        /* DMA request: set when DMA mode is active and the current phase
         * can accept/provide data. The firmware uses DMA for COMMAND,
         * DATA_IN, DATA_OUT, STATUS, and MSG_IN phases. */
        if (ncr->dma_active) {
            if (ncr->phase == SCSI_PHASE_COMMAND)
                val |= BAS_DMA_REQ;  /* Accept command bytes */
            if (ncr->phase == SCSI_PHASE_DATA_IN && ncr->data_pos < ncr->data_len)
                val |= BAS_DMA_REQ;
            if (ncr->phase == SCSI_PHASE_DATA_OUT && ncr->data_pos < ncr->data_len)
                val |= BAS_DMA_REQ;
            if (ncr->phase == SCSI_PHASE_STATUS)
                val |= BAS_DMA_REQ;
            if (ncr->phase == SCSI_PHASE_MSG_IN)
                val |= BAS_DMA_REQ;
        }
        /* End of DMA */
        if (ncr->dma_active && ncr->data_pos >= ncr->data_len)
            val |= BAS_END_DMA;
        return val;
    }

    case NCR_REG_IDATA:  /* Reg 6: Input Data (with DMA handshake) */
        if (ncr->phase == SCSI_PHASE_DATA_IN && ncr->data_pos < ncr->data_len)
            return ncr->data_buf[ncr->data_pos];
        return 0;

    case NCR_REG_RESET:  /* Reg 7: Reset Parity/Interrupts */
        /* Reading this register clears interrupt/parity flags */
        return 0;

    default:
        return 0;
    }
}

void ncr5380_write(ncr5380_t *ncr, int reg, uint8_t val)
{
    extern int verbose;
    static int write_trace = 0;
    /* Trace ALL register writes with PC */
    {
        static int ncr_trace = 0;
        if (ncr_trace < 100) {
            /* Read PC directly from Musashi's global state */
            extern unsigned int m68k_get_reg(void*, int);
            unsigned int pc = m68k_get_reg(NULL, 16); /* M68K_REG_PC = D0..D7(8)+A0..A7(8)+PC = index 16 */
            fprintf(stderr, "[NCR] W reg%d=0x%02X PC=0x%08X\n", reg, val, pc);
            ncr_trace++;
        }
    }
    switch (reg) {
    case NCR_REG_DATA:  /* Reg 0: Output Data */
        ncr->output_data = val;
        ncr->regs[0] = val;
        break;

    case NCR_REG_ICR:  /* Reg 1: Initiator Command */
        ncr->regs[NCR_REG_ICR] = val;

        /* RST: SCSI bus reset */
        if (val & ICR_RST) {
            ncr5380_reset(ncr);
            return;
        }

        /* SEL asserted: attempt device selection */
        fprintf(stderr, "[NCR-ICR] val=0x%02X SEL=%d BSY=%d phase=%d data=0x%02X\n",
                val, !!(val & ICR_SEL), !!(val & ICR_BSY), ncr->phase, ncr->output_data);
        if ((val & ICR_SEL) && !(val & ICR_BSY)
            && ncr->phase == SCSI_PHASE_FREE) {
            /* Data bus contains target ID bit mask */
            int id;
            for (id = 0; id < 8; id++) {
                if ((ncr->output_data & (1 << id))
                    && ncr->devices[id].present) {
                    ncr->selected_id = id;
                    set_phase(ncr, SCSI_PHASE_COMMAND);
                    ncr->cmd_pos = 0;
                    ncr->cmd_len = 0;
                    break;
                }
            }
            /* No device responded */
            if (ncr->selected_id < 0)
                set_phase(ncr, SCSI_PHASE_FREE);
        }

        /* ACK handshake */
        if (val & ICR_ACK) {
            switch (ncr->phase) {
            case SCSI_PHASE_COMMAND:
                if (ncr->cmd_pos < 16) {
                    ncr->cmd[ncr->cmd_pos++] = ncr->output_data;
                    if (ncr->cmd_pos == 1)
                        ncr->cmd_len = cmd_length(ncr->cmd[0]);
                    if (ncr->cmd_pos >= ncr->cmd_len)
                        execute_command(ncr);
                }
                break;
            case SCSI_PHASE_DATA_IN:
                if (ncr->data_pos < ncr->data_len)
                    ncr->data_pos++;
                if (ncr->data_pos >= ncr->data_len) {
                    set_phase(ncr, SCSI_PHASE_STATUS);
                }
                break;
            case SCSI_PHASE_DATA_OUT:
                if (ncr->data_pos < ncr->data_len) {
                    ncr->data_buf[ncr->data_pos++] = ncr->output_data;
                }
                if (ncr->data_pos >= ncr->data_len) {
                    /* Write data to disk */
                    scsi_device_t *dev = get_target(ncr);
                    if (dev && dev->image) {
                        uint32_t lba;
                        if (ncr->cmd[0] == 0x0A) {
                            lba = ((ncr->cmd[1] & 0x1F) << 16)
                                | (ncr->cmd[2] << 8) | ncr->cmd[3];
                        } else {
                            lba = (ncr->cmd[2] << 24) | (ncr->cmd[3] << 16)
                                | (ncr->cmd[4] << 8) | ncr->cmd[5];
                        }
                        fseek(dev->image, (long)lba * dev->block_size, SEEK_SET);
                        fwrite(ncr->data_buf, 1, ncr->data_len, dev->image);
                        fflush(dev->image);
                    }
                    set_phase(ncr, SCSI_PHASE_STATUS);
                }
                break;
            case SCSI_PHASE_STATUS:
                /* Status byte acknowledged, move to MSG_IN */
                ncr->msg_byte = 0x00;  /* COMMAND COMPLETE */
                set_phase(ncr, SCSI_PHASE_MSG_IN);
                break;
            case SCSI_PHASE_MSG_IN:
                /* Message acknowledged, bus free */
                ncr->selected_id = -1;
                set_phase(ncr, SCSI_PHASE_FREE);
                break;
            }
        }
        break;

    case NCR_REG_MODE:  /* Reg 2: Mode */
        ncr->regs[NCR_REG_MODE] = val;
        /* Arbitration mode */
        if (val & MODE_ARBITRATE) {
            ncr->phase = SCSI_PHASE_ARBITRATION;
            /* Arbitration succeeds immediately (we're the only initiator) */
            ncr->regs[NCR_REG_ICR] |= ICR_AIP;
        }
        /* DMA mode */
        if (val & MODE_DMA)
            ncr->dma_active = 1;
        else
            ncr->dma_active = 0;
        break;

    case NCR_REG_TCR:  /* Reg 3: Target Command */
        ncr->regs[NCR_REG_TCR] = val & 0x07;
        break;

    case 5:  /* Start DMA Send */
        ncr->dma_active = 1;
        break;

    case 6:  /* Start DMA Target Receive */
        ncr->dma_active = 1;
        break;

    case 7:  /* Start DMA Initiator Receive */
        ncr->dma_active = 1;
        break;

    default:
        ncr->regs[reg] = val;
        break;
    }
}

uint8_t ncr5380_dma_read(ncr5380_t *ncr)
{
    if (ncr->phase == SCSI_PHASE_DATA_IN && ncr->data_pos < ncr->data_len) {
        uint8_t val = ncr->data_buf[ncr->data_pos++];
        if (ncr->data_pos >= ncr->data_len)
            set_phase(ncr, SCSI_PHASE_STATUS);
        return val;
    }
    if (ncr->phase == SCSI_PHASE_STATUS) {
        uint8_t val = ncr->status_byte;
        ncr->msg_byte = 0x00;  /* COMMAND COMPLETE */
        set_phase(ncr, SCSI_PHASE_MSG_IN);
        return val;
    }
    if (ncr->phase == SCSI_PHASE_MSG_IN) {
        uint8_t val = ncr->msg_byte;
        ncr->selected_id = -1;
        set_phase(ncr, SCSI_PHASE_FREE);
        return val;
    }
    return 0xFF;
}

void ncr5380_dma_write(ncr5380_t *ncr, uint8_t val)
{
    if (ncr->phase == SCSI_PHASE_COMMAND) {
        /* Accept command bytes via DMA */
        if (ncr->cmd_pos < 16) {
            ncr->cmd[ncr->cmd_pos++] = val;
            if (ncr->cmd_pos == 1)
                ncr->cmd_len = cmd_length(ncr->cmd[0]);
            if (ncr->cmd_pos >= ncr->cmd_len)
                execute_command(ncr);
        }
    } else if (ncr->phase == SCSI_PHASE_DATA_OUT && ncr->data_pos < ncr->data_len) {
        ncr->data_buf[ncr->data_pos++] = val;
        if (ncr->data_pos >= ncr->data_len) {
            /* Write data to disk */
            scsi_device_t *dev = get_target(ncr);
            if (dev && dev->image) {
                uint32_t lba;
                if (ncr->cmd[0] == 0x0A) {
                    lba = ((ncr->cmd[1] & 0x1F) << 16)
                        | (ncr->cmd[2] << 8) | ncr->cmd[3];
                } else {
                    lba = (ncr->cmd[2] << 24) | (ncr->cmd[3] << 16)
                        | (ncr->cmd[4] << 8) | ncr->cmd[5];
                }
                fseek(dev->image, (long)lba * dev->block_size, SEEK_SET);
                fwrite(ncr->data_buf, 1, ncr->data_len, dev->image);
                fflush(dev->image);
            }
            set_phase(ncr, SCSI_PHASE_STATUS);
        }
    }
}

int ncr5380_attach_image(ncr5380_t *ncr, int id, const char *path, int block_size)
{
    if (id < 0 || id > 7) return -1;
    scsi_device_t *dev = &ncr->devices[id];

    dev->image = fopen(path, "r+b");
    if (!dev->image) {
        dev->image = fopen(path, "rb");
        if (!dev->image) {
            fprintf(stderr, "[SCSI] Cannot open image: %s\n", path);
            return -1;
        }
        fprintf(stderr, "[SCSI] Opened %s read-only at ID %d\n", path, id);
    } else {
        fprintf(stderr, "[SCSI] Opened %s read-write at ID %d\n", path, id);
    }

    fseek(dev->image, 0, SEEK_END);
    long size = ftell(dev->image);
    fseek(dev->image, 0, SEEK_SET);

    dev->block_size = block_size;
    dev->blocks = size / block_size;
    dev->present = 1;
    dev->sense_key = 0;
    dev->sense_asc = 0;

    fprintf(stderr, "[SCSI] ID %d: %ld bytes, %u blocks of %d bytes\n",
            id, size, dev->blocks, block_size);
    return 0;
}

void ncr5380_tick(ncr5380_t *ncr)
{
    /* Nothing time-dependent for now */
}
