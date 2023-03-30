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
    `include "src/i2cmb_write_generator.svh"
    `include "src/i2cmb_read_generator.svh"
    `include "src/i2cmb_alt_generator.svh"
    `include "src/i2cmb_test.svh"

endpackage