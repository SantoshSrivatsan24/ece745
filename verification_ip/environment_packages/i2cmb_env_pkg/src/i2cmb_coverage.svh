class i2cmb_coverage extends ncsu_component;

    // TODO: This class has knowledge of the DUT

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // I will have a generator that performs a read to every register
    // I need to assert that the default value is 0 somewhere
    // I'm not sure where to place that assertion
    // I think this goes in wb_coverage

    // TODO: How do I implement register testing?
    // 1. Is the address valid? (Make sure the address is in the range 0-2)
    // 2. Response to invalid address?
    // 3. Register or field aliasing
    // 4. Register and field default values
    // 5. Register access permissions enforced?
    // 6. Register fields accurate?
    
    // Should I have a covergroup that takes in two inputs? An address, and a value?
    // Each register has two bins. One for the wb data that we sent, and one for the wb data 
    // that we receive.

    // Should the register testing be of type "test"? What is a "test" type?


    // covergroup i2cmb_register_cg ();

        
        

    // endgroup



endclass