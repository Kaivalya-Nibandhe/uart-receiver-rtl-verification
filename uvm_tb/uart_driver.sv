class uart_driver extends uvm_driver #(uart_sequence_item);

    `uvm_component_utils(uart_driver)


    // =========================================================
    // Virtual interface
    // =========================================================

    virtual uart_if vif;


    // UART bit period
    time bit_period;


    // =========================================================
    // Expected stimulus analysis port
    //
    // Every sequence item is sent to the scoreboard so that
    // the scoreboard knows what type of test is being executed.
    // =========================================================

    uvm_analysis_port #(uart_sequence_item) expected_port;


    // =========================================================
    // Constructor
    // =========================================================

    function new(
        string name = "uart_driver",
        uvm_component parent = null
    );

        super.new(name, parent);

        expected_port = new(
            "expected_port",
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
                "UART_DRV",
                "Virtual interface not found"
            )

        end


        // 217 clocks × 40 ns
        bit_period = 8680ns;

    endfunction


    // =========================================================
    // Run phase
    // =========================================================

    virtual task run_phase(
        uvm_phase phase
    );

        uart_sequence_item req;
        uart_sequence_item expected_item;


        // UART idle state
        vif.rx <= 1'b1;


        forever begin

            // -------------------------------------------------
            // Get transaction from sequencer
            // -------------------------------------------------

            seq_item_port.get_next_item(req);


            // -------------------------------------------------
            // Create a copy for the scoreboard.
            // -------------------------------------------------

            expected_item =
                uart_sequence_item::type_id::create(
                    "expected_item"
                );


            expected_item.data =
                req.data;

            expected_item.frame_type =
                req.frame_type;


            // -------------------------------------------------
            // Send EVERY stimulus type to scoreboard.
            //
            // The scoreboard will determine what DUT response
            // is expected for that frame type.
            // -------------------------------------------------

            expected_port.write(
                expected_item
            );


            // -------------------------------------------------
            // Drive requested stimulus
            // -------------------------------------------------

            case (req.frame_type)


                // =================================================
                // Normal UART frame
                // =================================================

                uart_sequence_item::UART_NORMAL: begin

                    `uvm_info(
                        "UART_DRV",
                        $sformatf(
                            "Driving NORMAL frame: DATA = 0x%02h",
                            req.data
                        ),
                        UVM_MEDIUM
                    )

                    drive_uart_frame(
                        req.data
                    );

                end


                // =================================================
                // Invalid stop-bit frame
                // =================================================

                uart_sequence_item::UART_INVALID_STOP: begin

                    `uvm_info(
                        "UART_DRV",
                        $sformatf(
                            "Driving INVALID STOP frame: DATA = 0x%02h",
                            req.data
                        ),
                        UVM_MEDIUM
                    )

                    drive_invalid_stop_frame(
                        req.data
                    );

                end


                // =================================================
                // False start-bit test
                // =================================================

                uart_sequence_item::UART_FALSE_START: begin

                    `uvm_info(
                        "UART_DRV",
                        "Driving FALSE START pulse",
                        UVM_MEDIUM
                    )

                    drive_false_start();

                end


                default: begin

                    `uvm_error(
                        "UART_DRV",
                        "Unknown UART frame type"
                    )

                end

            endcase


            seq_item_port.item_done();

        end

    endtask


    // =========================================================
    // Normal UART frame
    // =========================================================

    virtual task drive_uart_frame(
        bit [7:0] data
    );

        // Idle
        vif.rx <= 1'b1;
        #(bit_period);


        // Start bit
        vif.rx <= 1'b0;
        #(bit_period);


        // Data bits - LSB first
        for (int i = 0; i < 8; i++) begin

            vif.rx <= data[i];
            #(bit_period);

        end


        // Stop bit
        vif.rx <= 1'b1;
        #(bit_period);

    endtask


    // =========================================================
    // Invalid stop-bit frame
    // =========================================================

    virtual task drive_invalid_stop_frame(
        bit [7:0] data
    );

        // Start bit
        vif.rx <= 1'b0;
        #(bit_period);


        // Data bits - LSB first
        for (int i = 0; i < 8; i++) begin

            vif.rx <= data[i];
            #(bit_period);

        end


        // -----------------------------------------------------
        // INVALID STOP BIT
        // Stop bit is deliberately driven LOW.
        // -----------------------------------------------------

        vif.rx <= 1'b0;
        #(bit_period);


        // Return to idle
        vif.rx <= 1'b1;

    endtask


    // =========================================================
    // False start-bit test
    // =========================================================

    virtual task drive_false_start();

        // Ensure idle
        vif.rx <= 1'b1;

        #(bit_period / 4);


        // Short LOW pulse
        vif.rx <= 1'b0;

        #(bit_period / 4);


        // Return to idle
        vif.rx <= 1'b1;

        #(bit_period);

    endtask


endclass
