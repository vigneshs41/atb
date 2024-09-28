module atb_tb;

    // Parameters
    localparam N = 256;

    // Testbench signals
    logic clk_write, clk_read;
    logic reset_n;
    logic is_branch_i;
    logic [31:0] pc_i;
    logic retire_valid_i;
    logic [31:0] retire_pc_i;
    logic [31:0] retire_tgt_pc_i;
    logic atb_valid_o;
    logic [31:0] atb_tgt_pc_o;

    // Instantiate the ATB
    atb #(.N(N)) dut (
        .clk(clk_write),           // Use the write clock for the main clock
        .reset_n(reset_n),
        .is_branch_i(is_branch_i),
        .pc_i(pc_i),
        .retire_valid_i(retire_valid_i),
        .retire_pc_i(retire_pc_i),
        .retire_tgt_pc_i(retire_tgt_pc_i),
        .atb_valid_o(atb_valid_o),
        .atb_tgt_pc_o(atb_tgt_pc_o)
    );

    // Clock generation for write
    always #5 clk_write = ~clk_write;

    // Clock generation for read
    always #5 clk_read = ~clk_read;

    // Test sequence
    initial begin
      $dumpfile("dump.vcd");
    $dumpvars(1);
        // Initialize signals
        clk_write = 0;
        clk_read = 0;
        reset_n = 0;
        is_branch_i = 0;
        pc_i = 0;
        retire_valid_i = 0;
        retire_pc_i = 0;
        retire_tgt_pc_i = 0;

        // Apply reset
        #10;
        reset_n = 1;

        // Test 1: Write to ATB on write clock
        @(posedge clk_write);
        retire_valid_i = 1;
        retire_pc_i = 32'h00000010;
        retire_tgt_pc_i = 32'h00001000;

        @(posedge clk_write);
        retire_valid_i = 0;

        // Test 2: Read from ATB on read clock
        @(posedge clk_read);
        is_branch_i = 1;
        pc_i = 32'h00000010;

        @(posedge clk_read);
        if (atb_valid_o && atb_tgt_pc_o == 32'h00001000) begin
            $display("Test Passed: ATB read back correct value");
        end
        else begin
            $display("Test Failed: ATB read back incorrect value");
        end

        // Test 3: Write another value and read back
        @(posedge clk_write);
        retire_valid_i = 1;
        retire_pc_i = 32'h00000020;
        retire_tgt_pc_i = 32'h00002000;

        @(posedge clk_write);
        retire_valid_i = 0;

        @(posedge clk_read);
        is_branch_i = 1;
        pc_i = 32'h00000020;

        @(posedge clk_read);
        if (atb_valid_o && atb_tgt_pc_o == 32'h00002000) begin
            $display("Test Passed: ATB read back correct value for pc_i 0x00000020");
        end
        else begin
            $display("Test Failed: ATB read back incorrect value for pc_i 0x00000020");
        end

        // Test 4: Read non-existent entry
        @(posedge clk_read);
        is_branch_i = 1;
        pc_i = 32'h00000030;

        @(posedge clk_read);
        if (!atb_valid_o && atb_tgt_pc_o == 32'h00000000) begin
            $display("Test Passed: ATB correctly indicated invalid for non-existent entry");
        end
        else begin
            $display("Test Failed: ATB incorrectly returned valid for non-existent entry");
        end

        // End of test
        $finish;
    end

endmodule