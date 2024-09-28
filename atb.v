module atb #(
    parameter N = 256  // Parameterizable size of the ATB
)(
    input  logic             clk,
    input  logic             reset_n,

    // Read Interface
    input  logic             is_branch_i,
    input  logic [31:0]      pc_i,

    // Write Interface
    input  logic             retire_valid_i,
    input  logic [31:0]      retire_pc_i,
    input  logic [31:0]      retire_tgt_pc_i,

    // Output Interface
    output logic             atb_valid_o,
    output logic [31:0]      atb_tgt_pc_o
);

    // Internal storage for the ATB
    typedef struct {
        logic [31:0] retire_pc;       // To store the retire PC
        logic [31:0] retire_tgt_pc;   // To store the retire Target PC
    } atb_entry_t;

    atb_entry_t target_buffer [N-1:0];
    logic [N-1:0] valid_bits;

    // Initialize the buffer and valid bits on reset
    always_ff @(negedge reset_n or posedge clk) begin
        if (!reset_n) begin
            valid_bits <= '0;  // Reset all valid bits
        end
        else begin
            // Write operation on retire
            if (retire_valid_i) begin
                target_buffer[retire_pc_i % N].retire_pc <= retire_pc_i;
                target_buffer[retire_pc_i % N].retire_tgt_pc <= retire_tgt_pc_i;
                valid_bits[retire_pc_i % N] <= 1'b1;  // Mark the entry as valid
            end
        end
    end

    // Read operation
    always_comb begin
        if (is_branch_i && valid_bits[pc_i % N] && target_buffer[pc_i % N].retire_pc == pc_i) begin
            atb_tgt_pc_o = target_buffer[pc_i % N].retire_tgt_pc;
            atb_valid_o = 1'b1;
        end
        else begin
            atb_tgt_pc_o = 32'b0;
            atb_valid_o = 1'b0;
        end
    end

endmodule