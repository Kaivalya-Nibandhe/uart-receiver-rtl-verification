class uart_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(uart_scoreboard)

    // ------------------------------------------------------------
    // Analysis FIFOs
    // ------------------------------------------------------------

    uvm_tlm_analysis_fifo #(uart_sequence_item)
        expected_fifo;

    uvm_tlm_analysis_fifo #(uart_sequence_item)
        actual_fifo;


    // ------------------------------------------------------------
    // Counters
    // ------------------------------------------------------------

    int pass_count;
    int fail_count;

    // Total number of scoreboard checks completed
    int check_count;


    // ------------------------------------------------------------
    // UART timing
    // ------------------------------------------------------------

    time bit_period;


    // ------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------

    function new(
        string name = "uart_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

        expected_fifo = new(
            "expected_fifo",
            this
        );

        actual_fifo = new(
            "actual_fifo",
            this
        );

        pass_count  = 0;
        fail_count  = 0;
        check_count = 0;

        bit_period = 8680ns;

    endfunction


    // ------------------------------------------------------------
    // Run phase
    // ------------------------------------------------------------

    virtual task run_phase(
        uvm_phase phase
    );

        uart_sequence_item expected_item;
        uart_sequence_item actual_item;
        uart_sequence_item unexpected_item;

        forever begin

            // ----------------------------------------------------
            // Get next expected transaction
            // ----------------------------------------------------

            expected_fifo.get(
                expected_item
            );


            // ====================================================
            // NORMAL UART TRANSACTION
            // ====================================================

            if (
                expected_item.frame_type ==
                uart_sequence_item::UART_NORMAL
            ) begin

                // Wait for the corresponding DUT transaction
                actual_fifo.get(
                    actual_item
                );


                // ------------------------------------------------
                // Check data and status
                // ------------------------------------------------

                if (
                    (actual_item.data ==
                     expected_item.data) &&

                    (actual_item.rx_valid == 1'b1) &&

                    (actual_item.framing_error == 1'b0)
                ) begin

                    pass_count++;
                    check_count++;

                    `uvm_info(
                        "UART_SCB",
                        $sformatf(
                            "PASS: NORMAL | Received = 0x%02h, Expected = 0x%02h | rx_valid = %0b | framing_error = %0b",
                            actual_item.data,
                            expected_item.data,
                            actual_item.rx_valid,
                            actual_item.framing_error
                        ),
                        UVM_MEDIUM
                    )

                end
                else begin

                    fail_count++;
                    check_count++;

                    `uvm_error(
                        "UART_SCB",
                        $sformatf(
                            "FAIL: NORMAL | Expected Data = 0x%02h, Actual Data = 0x%02h | Expected rx_valid = 1, Actual rx_valid = %0b | Expected framing_error = 0, Actual framing_error = %0b",
                            expected_item.data,
                            actual_item.data,
                            actual_item.rx_valid,
                            actual_item.framing_error
                        )
                    )

                end

            end


            // ====================================================
            // INVALID STOP-BIT TRANSACTION
            // ====================================================

            else if (
                expected_item.frame_type ==
                uart_sequence_item::UART_INVALID_STOP
            ) begin

                // The DUT is expected to report a framing error
                actual_fifo.get(
                    actual_item
                );


                // ------------------------------------------------
                // Check framing error
                // ------------------------------------------------

                if (
                    (actual_item.framing_error == 1'b1) &&
                    (actual_item.rx_valid == 1'b0)
                ) begin

                    pass_count++;
                    check_count++;

                    `uvm_info(
                        "UART_SCB",
                        $sformatf(
                            "PASS: INVALID_STOP | Framing error detected | Data = 0x%02h | rx_valid = %0b | framing_error = %0b",
                            actual_item.data,
                            actual_item.rx_valid,
                            actual_item.framing_error
                        ),
                        UVM_MEDIUM
                    )

                end
                else begin

                    fail_count++;
                    check_count++;

                    `uvm_error(
                        "UART_SCB",
                        $sformatf(
                            "FAIL: INVALID_STOP | Expected framing_error = 1 and rx_valid = 0 | Actual rx_valid = %0b | Actual framing_error = %0b",
                            actual_item.rx_valid,
                            actual_item.framing_error
                        )
                    )

                end

            end


            // ====================================================
            // FALSE START TRANSACTION
            // ====================================================

            else if (
                expected_item.frame_type ==
                uart_sequence_item::UART_FALSE_START
            ) begin

                // ------------------------------------------------
                // No DUT transaction should be generated.
                //
                // Wait long enough for the DUT to reject the
                // false start.
                // ------------------------------------------------

                #(bit_period);


                // ------------------------------------------------
                // Check whether the monitor reported anything.
                // ------------------------------------------------

                if (
                    actual_fifo.try_get(
                        unexpected_item
                    )
                ) begin

                    // Unexpected DUT response
                    fail_count++;
                    check_count++;

                    `uvm_error(
                        "UART_SCB",
                        $sformatf(
                            "FAIL: FALSE_START | Unexpected DUT transaction detected | Data = 0x%02h | rx_valid = %0b | framing_error = %0b",
                            unexpected_item.data,
                            unexpected_item.rx_valid,
                            unexpected_item.framing_error
                        )
                    )

                end
                else begin

                    // No DUT response = expected behavior
                    pass_count++;
                    check_count++;

                    `uvm_info(
                        "UART_SCB",
                        "PASS: FALSE_START | No rx_valid or framing_error response detected",
                        UVM_MEDIUM
                    )

                end

            end


            // ====================================================
            // UNKNOWN FRAME TYPE
            // ====================================================

            else begin

                fail_count++;
                check_count++;

                `uvm_error(
                    "UART_SCB",
                    "FAIL: Unknown UART frame type received"
                )

            end

        end

    endtask


    // ------------------------------------------------------------
    // Report phase
    // ------------------------------------------------------------

    virtual function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);

        `uvm_info(
            "UART_SCB",
            $sformatf(
                "Scoreboard Summary: PASS = %0d, FAIL = %0d, CHECKS = %0d",
                pass_count,
                fail_count,
                check_count
            ),
            UVM_NONE
        )

    endfunction

endclass
