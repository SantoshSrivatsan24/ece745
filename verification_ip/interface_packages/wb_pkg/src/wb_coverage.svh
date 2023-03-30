class wb_coverage extends ncsu_component #(.T(wb_transaction));

    cmd_t wb_commands;
    // byte csr_default_value;
    // byte cmdr_default_value;
    // byte dpr_default_value;

    // TODO: Implement a separate cover group for register testing?
    // TODO: I should have a condition to disable the other cover groups when doing register testing?

    covergroup wb_transaction_cg;

        option.per_instance = 1;
        option.name = get_full_name();
        
        wb_commands: coverpoint wb_commands
        {
        bins START      = {CMD_START};
        bins STOP       = {CMD_STOP};
        bins READ_ACK   = {CMD_READ_ACK};
        bins READ_NAK   = {CMD_READ_NAK};
        bins WRITE      = {CMD_WRITE};
        bins SET_BUS    = {CMD_SET_BUS};
        bins WAIT       = {CMD_WAIT};
        bins others     = default;
        }
    endgroup

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        wb_transaction_cg = new;
    endfunction

    virtual function void nb_put (T trans);
        this.wb_commands = cmd_t'(trans.data[2:0]);
        wb_transaction_cg.sample();
        $display ("wb command coverage = %0.2f %%", wb_transaction_cg.get_inst_coverage());
    endfunction

endclass