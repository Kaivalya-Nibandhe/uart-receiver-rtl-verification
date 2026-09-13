`timescale 1ns/10ps

// verilator lint_off DECLFILENAME
// verilator lint_off UNUSED

module uart_rx_tb;

    // ============================================================
    // TESTBENCH PARAMETERS
    // ============================================================

    parameter CLOCK_PERIOD_NS = 40;
    parameter CLKS_PER_BIT    = 217;
    parameter BIT_PERIOD      = CLKS_PER_BIT * CLOCK_PERIOD_NS;


    // ============================================================
    // TESTBENCH SIGNALS
    // ============================================================

    logic       clk;
    logic       rst;
    logic       rx;
    logic [7:0] rx_data;
    logic       rx_valid;
    logic framing_error;

    // ============================================================
    // VERIFICATION COMPONENT OBJECTS
    //
    // Objects are constructed during declaration so that they are
    // initialized before the initial blocks begin execution.
    // ============================================================

    uart_driver     driver     = new(BIT_PERIOD);
    uart_monitor    monitor    = new();
    uart_coverage   coverage   = new();
    uart_scoreboard scoreboard = new();


    // ============================================================
    // BACK-TO-BACK TEST DATA
    // ============================================================

    bit [7:0] back_to_back_data1;
    bit [7:0] back_to_back_data2;


    // ============================================================
    // DUT INSTANTIATION
    // ============================================================

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .rx       (rx),
        .rx_valid (rx_valid),
        .rx_data  (rx_data),
	.framing_error(framing_error)
    );


    // ============================================================
    // ASSERTION MODULE INSTANTIATION
    // ============================================================

    uart_assertions assertions_inst (
        .clk      (clk),
        .rst      (rst),
        .rx_valid (rx_valid),
        .rx_data  (rx_data)
    );


    // ============================================================
    // CLOCK GENERATION
    // ============================================================

    initial begin

        clk = 1'b0;

    end


    always #(CLOCK_PERIOD_NS / 2) clk = ~clk;


    // ============================================================
    // WAVEFORM DUMP
    // ============================================================

    initial begin
        
	$dumpfile("waves/dump.vcd");
        $dumpvars(0, uart_rx_tb);

    end


    // ============================================================
    // MONITOR PROCESS
    //
    // The monitor runs continuously and records every rising edge
    // of rx_valid.
    // ============================================================

    initial begin

        // Allow signal initialization before starting the monitor.
        #1;

        monitor.run_monitor(
            rx_valid,
            rx_data
        );

    end


    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================

    initial begin

        integer i;
        integer previous_transaction_count;


        // Allow the testbench signals and monitor to initialize.
        #1;


        // ========================================================
        // INITIAL SIGNAL VALUES
        // ========================================================

        rx  = 1'b1;
        rst = 1'b1;


        // ========================================================
        // RESET SEQUENCE
        // ========================================================

        repeat (2)
            @(posedge clk);

        rst = 1'b0;

        repeat (3)
            @(posedge clk);


        // ========================================================
        // TEST HEADER
        // ========================================================

        $display("");
        $display("==============================================");
        $display("             UART RX TEST START");
        $display("==============================================");
        $display("");


        // ========================================================
        // NORMAL UART TRANSACTIONS
        // ========================================================

        for (i = 0; i < 26; i = i + 1) begin

            // ----------------------------------------------------
            // Generate directed test patterns for the first eight
            // transactions and randomized data for the remaining
            // transactions.
            // ----------------------------------------------------

            case (i)

                0:
                    driver.run_transaction(
                        rx,
                        1'b1,
                        8'h00
                    );

                1:
                    driver.run_transaction(
                        rx,
                        1'b1,
                        8'hFF
                    );

                2:
                    driver.run_transaction(
                        rx,
                        1'b1,
                        8'hAA
                    );

                3:
                    driver.run_transaction(
                        rx,
                        1'b1,
                        8'h55
                    );

                4:
                    driver.run_transaction(
                        rx,
                        1'b1,
                        8'h01
                    );

                5:
                    driver.run_transaction(
                        rx,
                        1'b1,
                        8'h80
                    );

                6:
                    driver.run_transaction(
                        rx,
                        1'b1,
                        8'h81
                    );

                7:
                    driver.run_transaction(
                        rx,
                        1'b1,
                        8'h7E
                    );

                default:
                    driver.run_transaction(
                        rx,
                        1'b0,
                        8'h00
                    );

            endcase


            // ----------------------------------------------------
            // Sample the transmitted data for functional coverage.
            // ----------------------------------------------------

            coverage.sample(driver.data);


            // ----------------------------------------------------
            // Wait until the monitor detects the received frame.
            // ----------------------------------------------------

            wait (
                monitor.transaction_count == i + 1
            );


            // ----------------------------------------------------
            // Compare transmitted data against received data.
            // ----------------------------------------------------

            scoreboard.check(
                driver.data,
                monitor.last_rx_data
            );


            // Allow one clock cycle before the next transaction.
            @(posedge clk);

        end


        // ========================================================
        // INVALID STOP-BIT NEGATIVE TEST
        // ========================================================

        $display("");
        $display("==============================================");
        $display("       INVALID STOP-BIT NEGATIVE TEST");
        $display("==============================================");


        previous_transaction_count =
            monitor.transaction_count;


        driver.run_invalid_stop_test(rx);


        // Allow sufficient time for the DUT to process the frame.
        repeat (CLKS_PER_BIT * 2)
            @(posedge clk);


        if (monitor.transaction_count ==
            previous_transaction_count) begin

            $display(
                "PASS: Invalid stop-bit frame was correctly rejected"
            );

        end
        else begin

            $display(
                "FAIL: Invalid stop-bit frame was incorrectly accepted"
            );

        end


        // ========================================================
        // FALSE START-BIT NEGATIVE TEST
        // ========================================================

        $display("");
        $display("==============================================");
        $display("          FALSE START-BIT TEST");
        $display("==============================================");


        previous_transaction_count =
            monitor.transaction_count;


        driver.run_false_start_test(rx);


        // Allow sufficient time for the DUT to process the input.
        repeat (CLKS_PER_BIT * 2)
            @(posedge clk);


        if (monitor.transaction_count ==
            previous_transaction_count) begin

            $display(
                "PASS: False start-bit was correctly rejected"
            );

        end
        else begin

            $display(
                "FAIL: False start-bit was incorrectly accepted"
            );

        end


        // ========================================================
        // BACK-TO-BACK TRANSACTION TEST
        // ========================================================

        $display("");
        $display("==============================================");
        $display("          BACK-TO-BACK TEST");
        $display("==============================================");


        previous_transaction_count =
            monitor.transaction_count;


        driver.run_back_to_back_test(
            rx,
            back_to_back_data1,
            back_to_back_data2
        );


        // Wait until both back-to-back frames are received.
        wait (
            monitor.transaction_count ==
            previous_transaction_count + 2
        );


        // --------------------------------------------------------
        // Check the first back-to-back transaction.
        // --------------------------------------------------------

        scoreboard.check(
            back_to_back_data1,
            monitor.previous_rx_data
        );


        // --------------------------------------------------------
        // Check the second back-to-back transaction.
        // --------------------------------------------------------

        scoreboard.check(
            back_to_back_data2,
            monitor.last_rx_data
        );


        // ========================================================
        // FINAL TEST REPORTS
        // ========================================================

        $display("");
        $display("==============================================");
        $display("             UART RX TEST COMPLETE");
        $display("==============================================");


        $display(
            "TOTAL MONITORED TRANSACTIONS = %0d",
            monitor.transaction_count
        );


        // Display the functional coverage report.
        coverage.report();


        // Display the scoreboard report.
        scoreboard.report();


        $display("");
        $display("==============================================");
        $display("                 TEST FINISHED");
        $display("==============================================");


        $finish;

    end

endmodule

// verilator lint_on UNUSED
// verilator lint_on DECLFILENAME
