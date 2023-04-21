// Different types of wb transaction sequences that the 
// generator can generate
typedef enum bit [3:0] {      
    SEQ_START_WRITE_STOP,
    SEQ_START_READ_STOP,
    SEQ_START_WRITE_START,
    SEQ_START_READ_START,
    SEQ_WRITE_START,
    SEQ_READ_START,
    SEQ_WRITE_STOP,
    SEQ_READ_STOP
} seq_type_t;

// Byte-level FSM state encodings (obtained from mbyte.vhd)
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

// Bit-level FSM state encodings (obtained from mbit.vhd)
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

// Extract the fields of the CSR register
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

// Extract the fields of the FSMR register
typedef struct packed {
    bit_fsm_state_t bit_fsm_state;
    byte_fsm_state_t byte_fsm_state;
} fsmr_t;

typedef union packed {
    byte value;
    fsmr_t fields;
} fsmr_u;