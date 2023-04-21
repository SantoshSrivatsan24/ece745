class i2cmb_coverage extends ncsu_component #(.T(wb_transaction));

    fsmr_u fsmr;

    covergroup i2cmb_fsm_cg ();

    // Testplan 3.1: Ensure that all byte-level FSM states are covered
    byte_fsm_state: coverpoint fsmr.fields.byte_fsm_state
    {
    bins IDLE           = {S_IDLE};
    bins BUS_TAKEN      = {S_BUS_TAKEN};
    bins START_PENDING  = {S_START_PENDING};
    bins START          = {S_START};
    bins STOP           = {S_STOP};
    bins WRITE_BYTE     = {S_WRITE_BYTE};
    bins READ_BYTE      = {S_READ_BYTE};
    bins WAIT           = {S_WAIT};
    }

    // Testplan 3.2: Ensure that all byte-level FSM state transitions are exercised
    byte_fsm_transition: coverpoint fsmr.fields.byte_fsm_state
    {
    bins valid_transitions[] = 
        (S_IDLE => S_START_PENDING, S_WAIT, S_IDLE), 
        (S_START_PENDING => S_START),
        (S_START => S_BUS_TAKEN, S_IDLE),
        (S_BUS_TAKEN => S_START, S_WRITE_BYTE, S_READ_BYTE, S_STOP, S_BUS_TAKEN),
        (S_WRITE_BYTE => S_IDLE, S_BUS_TAKEN, S_WRITE_BYTE),
        (S_READ_BYTE => S_IDLE, S_BUS_TAKEN, S_READ_BYTE),
        (S_STOP => S_IDLE),
        (S_WAIT => S_IDLE);
    }

    // Testplan 3.3: Ensure that all bit-level FSM states are covered
    bit_fsm_state: coverpoint fsmr.fields.bit_fsm_state
    {   
    
    }
    endgroup

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        i2cmb_fsm_cg = new;
    endfunction

    virtual function void nb_put (T trans);
        if (trans.addr == FSMR_ADDR) begin
            this.fsmr = trans.data;
            i2cmb_fsm_cg.sample();
        end
    endfunction


endclass