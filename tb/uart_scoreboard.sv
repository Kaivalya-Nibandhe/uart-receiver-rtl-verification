`timescale 1ns/10ps

class uart_scoreboard;

    // Number of successful comparisons.
    integer pass_count;

    // Number of failed comparisons.
    integer fail_count;


    // ------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------
    function new();

        pass_count = 0;
        fail_count = 0;

    endfunction


    // ------------------------------------------------------------
    // Scoreboard Check Task
    //
    // Compares the expected UART data against the data captured
    // by the monitor and records the result.
    // ------------------------------------------------------------
    task automatic check(
        input bit [7:0] expected_data,
        input bit [7:0] actual_data
    );

        if (expected_data === actual_data) begin

            // Increment the pass counter when the values match.
            pass_count = pass_count + 1;

            $display(
                "SCOREBOARD PASS: EXPECTED = 0x%02h, ACTUAL = 0x%02h",
                expected_data,
                actual_data
            );

        end
        else begin

            // Increment the fail counter when the values differ.
            fail_count = fail_count + 1;

            $display(
                "SCOREBOARD FAIL: EXPECTED = 0x%02h, ACTUAL = 0x%02h",
                expected_data,
                actual_data
            );

        end

    endtask


    // ------------------------------------------------------------
    // Scoreboard Report Task
    //
    // Displays the total number of passed and failed comparisons
    // and provides the final scoreboard status.
    // ------------------------------------------------------------
    task automatic report();

        $display("==============================================");
        $display("              SCOREBOARD REPORT");
        $display("==============================================");


        // Display the number of successful comparisons.
        $display(
            "SCOREBOARD PASSED = %0d",
            pass_count
        );


        // Display the number of failed comparisons.
        $display(
            "SCOREBOARD FAILED = %0d",
            fail_count
        );


        // Display the final scoreboard status.
        if (fail_count == 0) begin

            $display("SCOREBOARD STATUS = PASS");

        end
        else begin

            $display("SCOREBOARD STATUS = FAIL");

        end

    endtask

endclass
