class i2c_transaction extends ncsu_transaction;

    // TODO: Figure out why we call this macro
    // It's so that we can register this object with a factory
    // I don't think we need to register the I2C transaction with the factory
    // Since the generator generates different types of `wb` transactions. Not I2C transactions
    // `ncsu_register_object (i2c_transaction)

    bit i2c_op;
    bit [6:0] i2c_addr;
    bit [7:0] i2c_data [];
    bit transfer_complete;

endclass