package i2cmb_env_pkg;

    import ncsu_pkg::*;
    import i2c_pkg::*;
    import wb_pkg::*;
    
    `include "i2cmb_macros.svh"
    `include "ncsu_macros.svh"
    
    `include "src/i2cmb_typedefs.svh"
    `include "src/i2cmb_env_configuration.svh"
    `include "src/i2cmb_coverage.svh"
    `include "src/i2cmb_scoreboard.svh"
    `include "src/i2cmb_predictor.svh"
    `include "src/i2cmb_environment.svh"

    `include "src/i2cmb_generator_base.svh"
    `include "src/i2cmb_generator_directed_test.svh"
    `include "src/i2cmb_generator_random_test.svh"
    `include "src/i2cmb_generator_i2c_operation.svh"
    `include "src/i2cmb_generator_32_writes.svh"
    `include "src/i2cmb_generator_32_reads.svh"
    `include "src/i2cmb_generator_64_alt_wr.svh"

    `include "src/i2cmb_test.svh"

endpackage