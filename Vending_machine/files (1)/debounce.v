`timescale 1ns/1ps
// =============================================================
// Coin Debouncer
// Cleans up a noisy/bouncy sensor input and produces a single,
// clean one-cycle pulse for each genuine coin insertion.
// Technique: 2-stage synchronizer (metastability protection)
// followed by a stable-cycle counter (debounce filter), then
// rising-edge detection on the filtered signal.
// =============================================================
module debounce #(
    parameter DEBOUNCE_CYCLES = 4   // consecutive stable cycles required
)(
    input  wire clk,
    input  wire rst_n,
    input  wire noisy_in,
    output reg  clean_pulse         // 1-cycle pulse per genuine insertion
);

    // ---------------- 2-stage synchronizer ----------------
    reg [1:0] sync_ff;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) sync_ff <= 2'b00;
        else        sync_ff <= {sync_ff[0], noisy_in};
    end
    wire sync_in = sync_ff[1];

    // ---------------- Debounce filter ----------------
    reg [3:0] count;
    reg       stable_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count        <= 4'd0;
            stable_state <= 1'b0;
        end else if (sync_in == stable_state) begin
            count <= 4'd0;                       // already stable, no change pending
        end else begin
            count <= count + 4'd1;
            if (count + 1 >= DEBOUNCE_CYCLES) begin
                stable_state <= sync_in;          // signal held long enough -> accept it
                count        <= 4'd0;
            end
        end
    end

    // ---------------- Rising-edge pulse generator ----------------
    reg prev_stable_state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_stable_state <= 1'b0;
            clean_pulse       <= 1'b0;
        end else begin
            prev_stable_state <= stable_state;
            clean_pulse       <= stable_state && !prev_stable_state;
        end
    end

endmodule
