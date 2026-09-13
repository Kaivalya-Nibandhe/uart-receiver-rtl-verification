`timescale 1ns/10ps

class uart_coverage;

    // ============================================================
    // DATA PATTERN COVERAGE
    //
    // Each counter represents a functional coverage bin.
    // ============================================================

    integer zero_count;
    integer ones_count;
    integer aa_count;
    integer five5_count;
    integer lsb_count;
    integer msb_count;
    integer edges_count;
    integer middle_count;
    integer other_count;


    // ============================================================
    // BIT-LEVEL COVERAGE
    //
    // For every bit, track whether both values have been observed:
    //
    //     0
    //     1
    //
    // Total bit-level bins = 8 bits × 2 states = 16 bins.
    // ============================================================

    integer bit0_zero;
    integer bit0_one;

    integer bit1_zero;
    integer bit1_one;

    integer bit2_zero;
    integer bit2_one;

    integer bit3_zero;
    integer bit3_one;

    integer bit4_zero;
    integer bit4_one;

    integer bit5_zero;
    integer bit5_one;

    integer bit6_zero;
    integer bit6_one;

    integer bit7_zero;
    integer bit7_one;


    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function new();

        // Initialize data-pattern coverage counters.
        zero_count   = 0;
        ones_count   = 0;
        aa_count     = 0;
        five5_count  = 0;
        lsb_count    = 0;
        msb_count    = 0;
        edges_count  = 0;
        middle_count = 0;
        other_count  = 0;


        // Initialize bit-level coverage counters.
        bit0_zero = 0;
        bit0_one  = 0;

        bit1_zero = 0;
        bit1_one  = 0;

        bit2_zero = 0;
        bit2_one  = 0;

        bit3_zero = 0;
        bit3_one  = 0;

        bit4_zero = 0;
        bit4_one  = 0;

        bit5_zero = 0;
        bit5_one  = 0;

        bit6_zero = 0;
        bit6_one  = 0;

        bit7_zero = 0;
        bit7_one  = 0;

    endfunction


    // ============================================================
    // SAMPLE DATA
    //
    // Updates the data-pattern and bit-level coverage counters
    // for the received 8-bit UART data.
    // ============================================================

    function void sample(
        input bit [7:0] data
    );

        // --------------------------------------------------------
        // DATA PATTERN COVERAGE
        // --------------------------------------------------------

        case (data)

            8'h00:
                zero_count = zero_count + 1;

            8'hFF:
                ones_count = ones_count + 1;

            8'hAA:
                aa_count = aa_count + 1;

            8'h55:
                five5_count = five5_count + 1;

            8'h01:
                lsb_count = lsb_count + 1;

            8'h80:
                msb_count = msb_count + 1;

            8'h81:
                edges_count = edges_count + 1;

            8'h7E:
                middle_count = middle_count + 1;

            default:
                other_count = other_count + 1;

        endcase


        // --------------------------------------------------------
        // BIT 0 COVERAGE
        // --------------------------------------------------------

        if (data[0] == 1'b0)
            bit0_zero = bit0_zero + 1;
        else
            bit0_one = bit0_one + 1;


        // --------------------------------------------------------
        // BIT 1 COVERAGE
        // --------------------------------------------------------

        if (data[1] == 1'b0)
            bit1_zero = bit1_zero + 1;
        else
            bit1_one = bit1_one + 1;


        // --------------------------------------------------------
        // BIT 2 COVERAGE
        // --------------------------------------------------------

        if (data[2] == 1'b0)
            bit2_zero = bit2_zero + 1;
        else
            bit2_one = bit2_one + 1;


        // --------------------------------------------------------
        // BIT 3 COVERAGE
        // --------------------------------------------------------

        if (data[3] == 1'b0)
            bit3_zero = bit3_zero + 1;
        else
            bit3_one = bit3_one + 1;


        // --------------------------------------------------------
        // BIT 4 COVERAGE
        // --------------------------------------------------------

        if (data[4] == 1'b0)
            bit4_zero = bit4_zero + 1;
        else
            bit4_one = bit4_one + 1;


        // --------------------------------------------------------
        // BIT 5 COVERAGE
        // --------------------------------------------------------

        if (data[5] == 1'b0)
            bit5_zero = bit5_zero + 1;
        else
            bit5_one = bit5_one + 1;


        // --------------------------------------------------------
        // BIT 6 COVERAGE
        // --------------------------------------------------------

        if (data[6] == 1'b0)
            bit6_zero = bit6_zero + 1;
        else
            bit6_one = bit6_one + 1;


        // --------------------------------------------------------
        // BIT 7 COVERAGE
        // --------------------------------------------------------

        if (data[7] == 1'b0)
            bit7_zero = bit7_zero + 1;
        else
            bit7_one = bit7_one + 1;

    endfunction


    // ============================================================
    // COVERAGE REPORT
    // ============================================================

    function void report();

        integer pattern_bins;
        integer pattern_covered;

        integer bit_bins;
        integer bit_covered;

        integer pattern_coverage;
        integer bit_coverage;


        // --------------------------------------------------------
        // DATA PATTERN COVERAGE CALCULATION
        // --------------------------------------------------------

        pattern_bins    = 9;
        pattern_covered = 0;


        if (zero_count > 0)
            pattern_covered = pattern_covered + 1;

        if (ones_count > 0)
            pattern_covered = pattern_covered + 1;

        if (aa_count > 0)
            pattern_covered = pattern_covered + 1;

        if (five5_count > 0)
            pattern_covered = pattern_covered + 1;

        if (lsb_count > 0)
            pattern_covered = pattern_covered + 1;

        if (msb_count > 0)
            pattern_covered = pattern_covered + 1;

        if (edges_count > 0)
            pattern_covered = pattern_covered + 1;

        if (middle_count > 0)
            pattern_covered = pattern_covered + 1;

        if (other_count > 0)
            pattern_covered = pattern_covered + 1;


        // Calculate integer percentage coverage.
        pattern_coverage =
            (pattern_covered * 100) / pattern_bins;


        // --------------------------------------------------------
        // BIT-LEVEL COVERAGE CALCULATION
        //
        // 8 bits × 2 possible values = 16 bins.
        // --------------------------------------------------------

        bit_bins    = 16;
        bit_covered = 0;


        if (bit0_zero > 0)
            bit_covered = bit_covered + 1;

        if (bit0_one > 0)
            bit_covered = bit_covered + 1;


        if (bit1_zero > 0)
            bit_covered = bit_covered + 1;

        if (bit1_one > 0)
            bit_covered = bit_covered + 1;


        if (bit2_zero > 0)
            bit_covered = bit_covered + 1;

        if (bit2_one > 0)
            bit_covered = bit_covered + 1;


        if (bit3_zero > 0)
            bit_covered = bit_covered + 1;

        if (bit3_one > 0)
            bit_covered = bit_covered + 1;


        if (bit4_zero > 0)
            bit_covered = bit_covered + 1;

        if (bit4_one > 0)
            bit_covered = bit_covered + 1;


        if (bit5_zero > 0)
            bit_covered = bit_covered + 1;

        if (bit5_one > 0)
            bit_covered = bit_covered + 1;


        if (bit6_zero > 0)
            bit_covered = bit_covered + 1;

        if (bit6_one > 0)
            bit_covered = bit_covered + 1;


        if (bit7_zero > 0)
            bit_covered = bit_covered + 1;

        if (bit7_one > 0)
            bit_covered = bit_covered + 1;


        // Calculate integer percentage coverage.
        bit_coverage =
            (bit_covered * 100) / bit_bins;


        // ========================================================
        // DISPLAY COVERAGE REPORT
        // ========================================================

        $display("");
        $display("==============================================");
        $display("           UART FUNCTIONAL COVERAGE");
        $display("==============================================");


        // --------------------------------------------------------
        // DATA PATTERN COVERAGE REPORT
        // --------------------------------------------------------

        $display("");
        $display("DATA PATTERN COVERAGE");
        $display("----------------------------------------------");

        $display("0x00 : %0d hits", zero_count);
        $display("0xFF : %0d hits", ones_count);
        $display("0xAA : %0d hits", aa_count);
        $display("0x55 : %0d hits", five5_count);
        $display("0x01 : %0d hits", lsb_count);
        $display("0x80 : %0d hits", msb_count);
        $display("0x81 : %0d hits", edges_count);
        $display("0x7E : %0d hits", middle_count);
        $display("OTHER: %0d hits", other_count);

        $display("----------------------------------------------");

        $display(
            "DATA PATTERN COVERAGE = %0d%% (%0d/%0d bins)",
            pattern_coverage,
            pattern_covered,
            pattern_bins
        );


        // --------------------------------------------------------
        // BIT-LEVEL COVERAGE REPORT
        // --------------------------------------------------------

        $display("");
        $display("BIT-LEVEL COVERAGE");
        $display("----------------------------------------------");

        $display(
            "BIT0 : 0=%0d  1=%0d",
            bit0_zero,
            bit0_one
        );

        $display(
            "BIT1 : 0=%0d  1=%0d",
            bit1_zero,
            bit1_one
        );

        $display(
            "BIT2 : 0=%0d  1=%0d",
            bit2_zero,
            bit2_one
        );

        $display(
            "BIT3 : 0=%0d  1=%0d",
            bit3_zero,
            bit3_one
        );

        $display(
            "BIT4 : 0=%0d  1=%0d",
            bit4_zero,
            bit4_one
        );

        $display(
            "BIT5 : 0=%0d  1=%0d",
            bit5_zero,
            bit5_one
        );

        $display(
            "BIT6 : 0=%0d  1=%0d",
            bit6_zero,
            bit6_one
        );

        $display(
            "BIT7 : 0=%0d  1=%0d",
            bit7_zero,
            bit7_one
        );

        $display("----------------------------------------------");

        $display(
            "BIT COVERAGE = %0d%% (%0d/%0d bins)",
            bit_coverage,
            bit_covered,
            bit_bins
        );

        $display("==============================================");

    endfunction

endclass
