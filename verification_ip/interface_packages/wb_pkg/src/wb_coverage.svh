class wb_coverage extends ncsu_component #(.T(wb_transaction));

    cmdr_u cmdr;
    rsp_t rsp;
    cmd_t cmd_sequence;


    covergroup wb_transaction_cg;

        option.per_instance = 1;
        option.name = get_full_name();
        
        // Testplan 2.11: Ensure that the DUT receives every possible byte-level command
        cmd: coverpoint cmdr.fields.cmd
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

        // Testplan 2.12: Ensure that the DUT provides every possible response
        rsp: coverpoint rsp
        {
        bins DON        = {RSP_DON};
        bins ARB_LOST   = {RSP_ARB_LOST};
        bins NAK        = {RSP_NAK};
        bins ERR        = {RSP_ERR};
        ignore_bins  IGNORE = {NULL};
        illegal_bins ILLEGAL_RSP = default;
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
            this.cmdr.value = trans.data;
            this.rsp = rsp_t'({cmdr.fields.don, cmdr.fields.nak, cmdr.fields.al, cmdr.fields.err});
            wb_transaction_cg.sample();
        end
    endfunction

endclass