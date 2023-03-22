package i2c_pkg;

    typedef enum bit {WRITE=1'b0, READ=1'b1} i2c_op_t;
    import ncsu_pkg::*;
    
    `include "ncsu_macros.svh"
    `include "src/i2c_transaction.svh"
    `include "src/i2c_configuration.svh"
    `include "src/i2c_driver.svh"
    `include "src/i2c_monitor.svh"
    `include "src/i2c_agent.svh"


endpackage