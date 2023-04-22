make clean compile optimize

make run_cli GEN_TYPE=i2cmb_generator_register_test
mv transcript transcript_register_test

make run_cli GEN_TYPE=i2cmb_generator_dut_test
mv transcript transcript_dut_test

make run_cli GEN_TYPE=i2cmb_generator_i2c_operation
mv transcript transcript_i2c_operation

make run_cli GEN_TYPE=i2cmb_generator_writes
mv transcript transcript_writes

make run_cli GEN_TYPE=i2cmb_generator_reads
mv transcript transcript_reads

make run_cli GEN_TYPE=i2cmb_generator_alt_rw
mv transcript transcript_alt_rw

make merge_coverage
