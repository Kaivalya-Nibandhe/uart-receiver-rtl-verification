class uart_coverage extends uvm_subscriber #(uart_sequence_item);

    `uvm_component_utils(uart_coverage)

    int sample_count;


    // ---------------------------------------------------------
    // UART Functional Coverage
    // ---------------------------------------------------------

    covergroup uart_cg with function sample(bit [7:0] data);

        option.per_instance = 1;


        // -----------------------------------------------------
        // Data-pattern coverage
        // -----------------------------------------------------

        data_pattern: coverpoint data {

            bins all_zeros  = {8'h00};
            bins all_ones   = {8'hFF};
            bins pattern_55 = {8'h55};
            bins pattern_AA = {8'hAA};

            bins low_values  = {[8'h01:8'h0F]};
            bins mid_low     = {[8'h10:8'h3F]};
            bins mid_high    = {[8'h40:8'hBF]};
            bins high_values = {[8'hC0:8'hFE]};

        }


        // -----------------------------------------------------
        // Individual bit coverage
        // -----------------------------------------------------

        bit_coverage: coverpoint data {

            wildcard bins bit_0_0 = {8'b???????0};
            wildcard bins bit_0_1 = {8'b???????1};

            wildcard bins bit_1_0 = {8'b??????0?};
            wildcard bins bit_1_1 = {8'b??????1?};

            wildcard bins bit_2_0 = {8'b?????0??};
            wildcard bins bit_2_1 = {8'b?????1??};

            wildcard bins bit_3_0 = {8'b????0???};
            wildcard bins bit_3_1 = {8'b????1???};

            wildcard bins bit_4_0 = {8'b???0????};
            wildcard bins bit_4_1 = {8'b???1????};

            wildcard bins bit_5_0 = {8'b??0?????};
            wildcard bins bit_5_1 = {8'b??1?????};

            wildcard bins bit_6_0 = {8'b?0??????};
            wildcard bins bit_6_1 = {8'b?1??????};

            wildcard bins bit_7_0 = {8'b0???????};
            wildcard bins bit_7_1 = {8'b1???????};

        }

    endgroup


    function new(
        string name = "uart_coverage",
        uvm_component parent = null
    );

        super.new(name, parent);

        sample_count = 0;

        uart_cg = new();

    endfunction


    // ---------------------------------------------------------
    // Receive transaction from monitor
    // ---------------------------------------------------------

    virtual function void write(
        uart_sequence_item t
    );

        sample_count++;

        uart_cg.sample(t.data);

        `uvm_info(
            "UART_COV",
            $sformatf(
                "Coverage sampled: DATA = 0x%02h, Sample Count = %0d",
                t.data,
                sample_count
            ),
            UVM_HIGH
        )

    endfunction


    // ---------------------------------------------------------
    // Coverage report
    // ---------------------------------------------------------

    virtual function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);

        `uvm_info(
            "UART_COV",
            $sformatf(
                "Coverage Samples = %0d",
                sample_count
            ),
            UVM_NONE
        )

        `uvm_info(
            "UART_COV",
            $sformatf(
                "UART Functional Coverage = %0.2f%%",
                uart_cg.get_inst_coverage()
            ),
            UVM_NONE
        )

    endfunction

endclass
