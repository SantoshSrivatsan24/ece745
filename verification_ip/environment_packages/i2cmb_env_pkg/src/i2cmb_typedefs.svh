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