class uart_env extends uvm_env;

    `uvm_component_utils(uart_env)

    uart_agent      agent;
    uart_scoreboard scoreboard;
    uart_coverage   coverage;


    function new(
        string name = "uart_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        agent = uart_agent::type_id::create(
            "agent",
            this
        );

        scoreboard = uart_scoreboard::type_id::create(
            "scoreboard",
            this
        );

        coverage = uart_coverage::type_id::create(
            "coverage",
            this
        );

    endfunction


    virtual function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);

        // Actual DUT output → scoreboard
        agent.monitor.analysis_port.connect(
            scoreboard.actual_fifo.analysis_export
        );

        // Expected transaction → scoreboard
        agent.driver.expected_port.connect(
            scoreboard.expected_fifo.analysis_export
        );

        // Actual DUT output → functional coverage
        agent.monitor.analysis_port.connect(
            coverage.analysis_export
        );

    endfunction

endclass
