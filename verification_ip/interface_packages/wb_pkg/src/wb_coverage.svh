class wb_coverage extends ncsu_component #(.T(wb_transaction));

    covergroup wb_transaction_cg with function sample (wb_op_t op, cmd_t cmd, rsp_t rsp);

        option.per_instance = 1;
        option.name = get_full_name();
        
        // Testplan 2.11: Ensure that the DUT receives every possible byte-level command
        cmd: coverpoint cmd
        {
            bins valid_cmd[] = {CMD_START, CMD_STOP, CMD_READ_ACK, CMD_READ_NAK, CMD_WRITE, CMD_SET_BUS, CMD_WAIT};
        }

        // Testplan 2.12: Ensure that every legal command sequence is hit
        cmd_sequence: coverpoint cmd iff (op == WB_WRITE)
        {
            bins cmd_seq[] = 
                (CMD_START => CMD_START, CMD_STOP, CMD_WRITE),
                (CMD_STOP => CMD_START, CMD_WAIT, CMD_SET_BUS),
                (CMD_READ_ACK => CMD_READ_ACK, CMD_READ_NAK),
                (CMD_READ_NAK => CMD_START, CMD_STOP),
                (CMD_WRITE => CMD_START, CMD_STOP, CMD_WRITE, CMD_READ_ACK, CMD_READ_NAK),
                (CMD_SET_BUS => CMD_START, CMD_STOP, CMD_SET_BUS, CMD_WAIT),
                (CMD_WAIT => CMD_START, CMD_SET_BUS, CMD_WAIT);
        }

        // Testplan 2.13: Ensure that the DUT provides every possible response
        rsp: coverpoint rsp iff (op == WB_READ) // Only sample response when we read the CMDR
        {
            bins valid_rsp[] = {RSP_DON, RSP_NAK, RSP_ERR};
        }

    endgroup

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        wb_transaction_cg = new;
    endfunction

    virtual function void nb_put (T trans);
        cmdr_u cmdr;
        cmd_t cmd;
        rsp_t rsp;
        wb_op_t op;
        if (trans.addr == CMDR_ADDR) begin
            cmdr.value = trans.data;
            cmd = cmdr.fields.cmd;
            rsp = rsp_t'({cmdr.fields.don, cmdr.fields.nak, cmdr.fields.al, cmdr.fields.err});
            op = wb_op_t'(trans.we);
            wb_transaction_cg.sample(op, cmd, rsp);
        end
    endfunction


endclass