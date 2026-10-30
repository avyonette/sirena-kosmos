typedef enum bit[5:0] {
	MC_CMD_NOP = 6'd0,
	MC_CMD_READ8 = 6'd1,
	MC_CMD_READ16 = 6'd2,
	MC_CMD_READ32 = 6'd4,
	MC_CMD_WRITE8 = 6'd8,
	MC_CMD_WRITE16 = 6'd16,
	MC_CMD_WRITE32 = 6'd32
} MemCtrlCmd;

typedef enum bit[2:0] {
	MC_CMD_READ8_I = 3'd0,
	MC_CMD_READ16_I = 3'd1,
	MC_CMD_READ32_I = 3'd2,
	MC_CMD_WRITE8_I = 3'd3,
	MC_CMD_WRITE16_I = 3'd4,
	MC_CMD_WRITE32_I = 3'd5
} MemCtrlCmdIndex;