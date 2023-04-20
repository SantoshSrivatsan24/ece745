typedef enum bit [1:0] {
    CSR_ADDR = 2'h0,
    DPR_ADDR = 2'h1,
    CMDR_ADDR = 2'h2,
    FSMR_ADDR = 2'h3
} addr_t;

typedef enum bit [2:0] {
    CMD_START       = 3'b100,
    CMD_STOP        = 3'b101,
    CMD_READ_ACK    = 3'b010,
    CMD_READ_NAK    = 3'b011,
    CMD_WRITE       = 3'b001,
    CMD_SET_BUS     = 3'b110,
    CMD_WAIT        = 3'b000
} cmd_t;

typedef enum bit [3:0] {
    NULL            = 4'b0000,
    RSP_DON         = 4'b1000,
    RSP_ARB_LOST    = 4'b0100,
    RSP_NAK         = 4'b0010,
    RSP_ERR         = 4'b0001
} rsp_t;

///////////////////////////////////////////////

// Byte-level FSM state encodings obtained from mbyte.vhd
typedef enum bit [3:0] {      
    S_IDLE,             // Idle
    S_BUS_TAKEN,        // Bus is taken
    S_START_PENDING,    // Waiting for right moment to capture bus
    S_START,            // Sending Start condition (Capturing the bus)
    S_STOP,             // Sending Stop condition (Releasing the bus)
    S_WRITE_BYTE,       // Sending a byte
    S_READ_BYTE,        // Receiving a byte
    S_WAIT              // Receiving a byte
} byte_fsm_state_t;

// Bit-level FSM state encodings obtained from mbit.vhd
typedef enum bit [3:0] {
    S_IDLE2,            // Idle

    S_START_A,          // Start condition generating
    S_START_B,          // Start condition generating
    S_START_C,          // Start condition generating

    S_RW_A,             // Bit Read/Write
    S_RW_B,             // Bit Read/Write
    S_RW_C,             // Bit Read/Write
    S_RW_D,             // Bit Read/Write
    S_RW_E,             // Bit Read/Write

    S_STOP_A,           // Stop condition generating
    S_STOP_B,           // Stop condition generating
    S_STOP_C,           // Stop condition generating
    S_RSTART_A,         // Preparation for Repeated Start
    S_RSTART_B,         // Preparation for Repeated Start
    S_RSTART_C          // Preparation for Repeated Start
} bit_fsm_state_t;

///////////////////////////////////////////////

typedef struct packed {
    bit e;
    bit ie;
    bit bb;
    bit bc;
    bit [3:0] bus_id;
} csr_t;

typedef union packed {
    byte value;
    csr_t fields;
} csr_u;

// Extract the fields of the CMDR register
typedef struct packed {
    bit don;
    bit nak;
    bit al;
    bit err;
    bit r;
    cmd_t cmd;
} cmdr_t;

typedef union packed {
    byte value;
    cmdr_t fields;
} cmdr_u;

// Extract the fields of the FSMR register
typedef struct packed {
    bit_fsm_state_t bit_fsm_state;
    byte_fsm_state_t byte_fsm_state;
} fsmr_t;

typedef union packed {
    byte value;
    fsmr_t fields;
} fsmr_u;

