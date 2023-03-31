class i2cmb_coverage extends ncsu_component #(.T(wb_transaction));

    bit byte_fsm_state;
    bit byte_fsm_transition;
    bit bit_fsm_state;


    covergroup i2cmb_env_cg ();

    // TODO: Testplan 3.1
    byte_fsm_state: coverpoint byte_fsm_state
    {

    }
    // TODO: Testplan 3.2
    byte_fsm_transition: coverpoint byte_fsm_transition
    {

    }
    // TODO: Testplan 3.3
    bit_fsm_state: coverpoint bit_fsm_state
    {

    }
        
    endgroup

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        i2cmb_env_cg = new;
    endfunction

    virtual function void nb_put (T trans);
        i2cmb_env_cg.sample();
    endfunction


endclass