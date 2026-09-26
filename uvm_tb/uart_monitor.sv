class uart_monitor extends uvm_monitor;

    `uvm_component_utils(uart_monitor)


    // =========================================================
    // Virtual interface
    // =========================================================

    virtual uart_if vif;


    // =========================================================
    // Analysis port
    //
    // Sends observed DUT responses to the scoreboard and
    // coverage collector.
    // =========================================================

    uvm_analysis_port #(uart_sequence_item) analysis_port;


    // =========================================================
    // Constructor
    // =========================================================

    function new(
        string name = "uart_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        analysis_port = new(
            "analysis_port",
            this
        );

    endfunction


    // =========================================================
    // Build phase
    // =========================================================

    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);


        if (!uvm_config_db#(virtual uart_if)::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "UART_MON",
                "Virtual interface not found"
            )

        end

    endfunction


    // =========================================================
    // Run phase
    //
    // The monitor waits for either:
    //
    //   1. rx_valid
    //   2. framing_error
    //
    // This allows the monitor to observe both successful UART
    // receptions and explicit framing-error responses.
    // =========================================================

    virtual task run_phase(
        uvm_phase phase
    );

        uart_sequence_item item;


        forever begin

            // -------------------------------------------------
            // Wait for a DUT response.
            //
            // Normal frame:
            //     rx_valid goes HIGH
            //
            // Invalid stop:
            //     framing_error goes HIGH
            // -------------------------------------------------

            @(posedge vif.rx_valid or
              posedge vif.framing_error);


            // -------------------------------------------------
            // Create a transaction representing the DUT
            // response.
            // -------------------------------------------------

            item = uart_sequence_item::type_id::create(
                "item",
                this
            );


            // -------------------------------------------------
            // Capture DUT outputs.
            // -------------------------------------------------

            item.data =
                vif.rx_data;

            item.rx_valid =
                vif.rx_valid;

            item.framing_error =
                vif.framing_error;


            // -------------------------------------------------
            // The monitor does not decide whether the stimulus
            // was NORMAL / INVALID_STOP / FALSE_START.
            //
            // It reports only what the DUT actually produced.
            // -------------------------------------------------

            if (item.framing_error) begin

                `uvm_info(
                    "UART_MON",
                    $sformatf(
                        "DUT reported FRAMING ERROR: DATA = 0x%02h, rx_valid = %0b",
                        item.data,
                        item.rx_valid
                    ),
                    UVM_MEDIUM
                )

            end
            else if (item.rx_valid) begin

                `uvm_info(
                    "UART_MON",
                    $sformatf(
                        "Received DATA = 0x%02h, rx_valid = %0b, framing_error = %0b",
                        item.data,
                        item.rx_valid,
                        item.framing_error
                    ),
                    UVM_MEDIUM
                )

            end


            // -------------------------------------------------
            // Publish observed transaction.
            // -------------------------------------------------

            analysis_port.write(item);

        end

    endtask

endclass
