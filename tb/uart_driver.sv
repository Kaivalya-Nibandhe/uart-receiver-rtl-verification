`timescale 1ns/10ps


//============================================================
// UART Driver
//
// Generates UART stimulus for the UART receiver DUT.
//
// UART configuration:
//   - 8 data bits
//   - No parity
//   - 1 stop bit
//   - LSB-first transmission
//
// The driver directly controls the RX signal and generates
// the required UART timing using simulation delays.
//
// Note:
//   The timing delays used by this class are intended for the
//   simulation testbench and are not synthesizable.
//============================================================

class uart_driver;


    //========================================================
    // Driver parameters and transaction data
    //========================================================

    // Duration of one UART bit in nanoseconds.
    integer bit_period;

    // Data currently being transmitted.
    rand bit [7:0] data;


    //========================================================
    // Constructor
    //========================================================

    function new(
        input integer bit_period_in
    );

        bit_period = bit_period_in;

    endfunction


    //========================================================
    // Task: Generate and drive a normal UART transaction
    //
    // Arguments:
    //   rx             : UART RX line driven by the testbench
    //   directed       : Selects directed or randomized data
    //   directed_data  : Data used when directed = 1
    //
    // If directed = 1:
    //   The specified directed_data value is transmitted.
    //
    // If directed = 0:
    //   The data variable is randomized before transmission.
    //========================================================

    task automatic run_transaction(
        ref logic       rx,
        input bit       directed,
        input bit [7:0] directed_data
    );

        integer bit_idx;


        //====================================================
        // Generate transaction data
        //====================================================

        if (directed) begin

            // Use the directed data pattern.
            data = directed_data;

        end
        else begin

            // Generate a randomized 8-bit data value.
            if (randomize() == 0) begin

                $display(
                    "TEST FAILED: Transaction randomization failed"
                );

                $finish;

            end

        end


        //====================================================
        // Display transmitted data
        //====================================================

        $display(
            "TX DATA = 0x%02h",
            data
        );


        //====================================================
        // Start bit
        //
        // UART uses an active-LOW start bit.
        //====================================================

        rx = 1'b0;

        #(bit_period);


        //====================================================
        // Data bits
        //
        // UART transmits the least-significant bit first.
        //====================================================

        for (
            bit_idx = 0;
            bit_idx < 8;
            bit_idx = bit_idx + 1
        ) begin

            rx = data[bit_idx];

            #(bit_period);

        end


        //====================================================
        // Stop bit
        //
        // The UART stop bit must be HIGH.
        //====================================================

        rx = 1'b1;

        #(bit_period);

    endtask


    //========================================================
    // Task: Invalid stop-bit test
    //
    // Sends a complete data field but drives the stop bit LOW.
    // The DUT is expected to reject this frame and must not
    // generate a valid receive indication.
    //========================================================

    task automatic run_invalid_stop_test(
        ref logic rx
    );

        integer  bit_idx;
        bit [7:0] test_data;


        // Data pattern used for the negative test.
        test_data = 8'hA5;

        $display("TX INVALID STOP-BIT TEST");


        //====================================================
        // Start bit
        //====================================================

        rx = 1'b0;

        #(bit_period);


        //====================================================
        // Data bits
        //
        // Transmit the data LSB first.
        //====================================================

        for (
            bit_idx = 0;
            bit_idx < 8;
            bit_idx = bit_idx + 1
        ) begin

            rx = test_data[bit_idx];

            #(bit_period);

        end


        //====================================================
        // Invalid stop bit
        //
        // A valid UART stop bit must be HIGH. Driving LOW
        // should cause the DUT to reject the frame.
        //====================================================

        rx = 1'b0;

        #(bit_period);


        // Return the RX line to its idle HIGH level.
        rx = 1'b1;

    endtask


    //========================================================
    // Task: Back-to-back frame test
    //
    // Sends two complete UART frames consecutively without
    // inserting an additional idle gap between them.
    //========================================================

    task automatic run_back_to_back_test(
        ref logic       rx,
        output bit [7:0] data1,
        output bit [7:0] data2
    );

        integer bit_idx;


        // Fixed data values for the back-to-back test.
        data1 = 8'h3C;
        data2 = 8'hA7;


        $display("BACK-TO-BACK TEST");
        $display("FRAME 1 = 0x%02h", data1);
        $display("FRAME 2 = 0x%02h", data2);


        //====================================================
        // Frame 1
        //====================================================

        // Start bit
        rx = 1'b0;

        #(bit_period);


        // Data bits
        for (
            bit_idx = 0;
            bit_idx < 8;
            bit_idx = bit_idx + 1
        ) begin

            rx = data1[bit_idx];

            #(bit_period);

        end


        // Stop bit
        rx = 1'b1;

        #(bit_period);


        //====================================================
        // Frame 2
        //====================================================

        // Start bit
        rx = 1'b0;

        #(bit_period);


        // Data bits
        for (
            bit_idx = 0;
            bit_idx < 8;
            bit_idx = bit_idx + 1
        ) begin

            rx = data2[bit_idx];

            #(bit_period);

        end


        // Stop bit
        rx = 1'b1;

        #(bit_period);

    endtask


    //========================================================
    // Task: False start-bit test
    //
    // Generates a short LOW pulse that is shorter than half
    // of a UART bit period.
    //
    // The DUT should detect the possible start bit but reject
    // it during half-bit validation because RX has returned
    // HIGH.
    //========================================================

    task automatic run_false_start_test(
        ref logic rx
    );

        $display("FALSE START-BIT TEST");


        // Pull RX LOW to imitate a possible start bit.
        rx = 1'b0;


        // Keep RX LOW for only one-quarter of a bit period.
        #(bit_period / 4);


        // Return RX to the idle HIGH level.
        rx = 1'b1;


        // Allow the DUT to process and reject the false start.
        #(bit_period);

    endtask


endclass
