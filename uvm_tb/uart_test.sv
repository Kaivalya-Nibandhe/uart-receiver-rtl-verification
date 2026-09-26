class uart_test extends uvm_test;

    `uvm_component_utils(uart_test)

    uart_env      env;
    uart_sequence seq;


    // ------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------

    function new(
        string name = "uart_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ------------------------------------------------------------
    // Build phase
    // ------------------------------------------------------------

    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        env = uart_env::type_id::create(
            "env",
            this
        );

    endfunction


    // ------------------------------------------------------------
    // Run phase
    // ------------------------------------------------------------

    virtual task run_phase(
        uvm_phase phase
    );

        phase.raise_objection(this);


        // --------------------------------------------------------
        // Start UART sequence
        // --------------------------------------------------------

        `uvm_info(
            "UART_TEST",
            "Starting UART sequence",
            UVM_LOW
        )

        seq = uart_sequence::type_id::create(
            "seq"
        );

        seq.start(
            env.agent.sequencer
        );


        // --------------------------------------------------------
        // Wait for scoreboard to process ALL transactions
        //
        // Sequence contains:
        //
        //   18 normal transactions
        //    1 invalid-stop transaction
        //    1 false-start transaction
        //
        // Total = 20 scoreboard checks
        // --------------------------------------------------------

        wait (
            env.scoreboard.pass_count +
            env.scoreboard.fail_count ==
            seq.total_transaction_count
        );


        // --------------------------------------------------------
        // Report sequence completion
        // --------------------------------------------------------

        `uvm_info(
            "UART_TEST",
            $sformatf(
                "UART sequence completed and scoreboard finished. Valid = %0d, Total = %0d",
                seq.valid_transaction_count,
                seq.total_transaction_count
            ),
            UVM_LOW
        )


        // --------------------------------------------------------
        // Drop objection
        // --------------------------------------------------------

        phase.drop_objection(this);

    endtask

endclass
