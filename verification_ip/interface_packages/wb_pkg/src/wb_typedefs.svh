typedef enum bit [2:0] {
    CMD_START       = 3'b100,
    CMD_STOP        = 3'b101,
    CMD_READ_ACK    = 3'b010,
    CMD_READ_NAK    = 3'b011,
    CMD_WRITE       = 3'b001,
    CMD_SET_BUS     = 3'b110,
    CMD_WAIT        = 3'b000
} cmd_t;

typedef enum bit [2:0] {
    RSP_DON         = 3'b000,
    RSP_ARB_LOST    = 3'b010,
    RSP_NAK         = 3'b001,
    RSP_BYTE        = 3'b100,
    RSP_ERR         = 3'b011
} rsp_t;

typedef enum bit [1:0] {
    CSR_ADDR = 2'h0,
    DPR_ADDR = 2'h1,
    CMDR_ADDR = 2'h2
} addr_t;
