class wb_coverage extends ncsu_component #(.T(wb_transaction));

    cmd_t cmd;
    rsp_t rsp;
    cmd_t cmd_sequence;


    covergroup wb_transaction_cg;

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
        illegal_bins ILLEGAL_CMD = default;
        }

        // TODO: Testplan 2.13
        rsp: coverpoint rsp
        {

        }

        // TODO: Testplan 2.14
        cmd_x_rsp: cross cmd, rsp 
        {

        }

        // TODO: Testplan 4.1
        cmd_sequence: coverpoint cmd_sequence
        {

        }

    endgroup

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        wb_transaction_cg = new;
    endfunction

    virtual function void nb_put (T trans);
        if (trans.addr == CMDR_ADDR) begin
            this.cmd = cmd_t'(trans.data[2:0]);
            wb_transaction_cg.sample();
        end
    endfunction

endclass