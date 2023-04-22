class wb_coverage extends ncsu_component #(.T(wb_transaction));

    covergroup wb_transaction_cg with function sample (wb_op_t op, cmd_t cmd, rsp_t rsp);

        option.per_instance = 1;
        option.name = get_full_name();
        
        // Testplan 2.11: Ensure that the DUT receives every possible byte-level command
        cmd: coverpoint cmd
        {
        bins START      = {CMD_START};
        bins STOP       = {CMD_STOP};
        bins READ_ACK   = {CMD_READ_ACK};
        bins READ_NAK   = {CMD_READ_NAK};
        bins WRITE      = {CMD_WRITE};
        bins SET_BUS    = {CMD_SET_BUS};
        bins WAIT       = {CMD_WAIT};
        }

        // Testplan 2.12: Ensure that the DUT provides every possible response
        rsp: coverpoint rsp iff (op == WB_READ)
        {
        bins DON        = {RSP_DON};
        bins NAK        = {RSP_NAK};
        bins ARB_LOST   = {RSP_ARB_LOST};
        bins ERR        = {RSP_ERR};
        }

        // TODO: Testplan 2.14
        cmd_x_rsp: cross cmd, rsp 
        {
         
        }

        // TODO: Testplan 4.1
        cmd_sequence: coverpoint cmd
        {

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