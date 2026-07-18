`timescale 1ns/1ps
// =============================================================
// Premium Vending Machine - Core FSM + Datapath (Verilog HDL)
// Features: 4 items with inventory tracking, denomination-wise
// change return (greedy algorithm), insufficient-funds handling,
// sold-out handling, idle-timeout auto-refund, cancel/refund,
// card/UPI payment option, revenue + transaction counters.
//
// NOTE: coin_5/coin_10/coin_20 inputs are assumed to already be
// clean, debounced pulses -- see vending_machine_top.v, which
// instantiates the debounce module in front of this core.
// card_pay is assumed pre-validated by an external payment
// terminal (this controller does not implement a card/UPI
// protocol itself, only reacts to its "approved" pulse).
// =============================================================
module vending_machine_premium #(
    parameter INIT_STOCK     = 3,
    parameter TIMEOUT_CYCLES = 20
)(
    input                clk,
    input                rst_n,
    input                coin_5,
    input                coin_10,
    input                coin_20,
    input        [2:0]   item_sel,     // 000=none, 001=Potato Chips, 010=Cold Drink,
                                        // 011=Mineral Water, 100=Chocolate Bar
    input                cancel,
    input                card_pay,     // pulse: external payment terminal approved payment

    output reg   [3:0]   dispense,       // one-hot pulse per item
    output reg   [3:0]   sold_out_flag,  // one-hot pulse per item
    output reg           insufficient_flag,
    output reg           card_txn_flag,  // pulse: this dispense was paid by card
    output reg   [3:0]   change_20,
    output reg   [3:0]   change_10,
    output reg   [3:0]   change_5,
    output wire  [7:0]   amount_disp,
    output wire  [7:0]   stock_disp,     // {stock_D,stock_C,stock_B,stock_A}, 2 bits each
    output wire  [15:0]  total_revenue,  // Rs collected across all completed sales
    output wire  [7:0]   total_txns      // count of completed sales
);

    // ---------------- Item prices ----------------
    // Item 0 = Potato Chips (Rs 15)   |  Item 2 = Mineral Water (Rs 10)
    // Item 1 = Cold Drink   (Rs 25)   |  Item 3 = Chocolate Bar (Rs 20)
    reg [7:0] price [0:3];
    initial begin
        price[0] = 8'd15;  // Potato Chips
        price[1] = 8'd25;  // Cold Drink
        price[2] = 8'd10;  // Mineral Water
        price[3] = 8'd20;  // Chocolate Bar
    end

    // ---------------- FSM state encoding ----------------
    parameter IDLE         = 3'd0;
    parameter INSUFFICIENT = 3'd1;
    parameter SOLD_OUT     = 3'd2;
    parameter DISPENSE     = 3'd3;
    parameter REFUND       = 3'd4;

    reg [2:0] state, next_state;
    reg [7:0] amount, next_amount;
    reg [7:0] idle_timer, next_idle_timer;
    reg [1:0] stock [0:3];
    reg [1:0] next_stock [0:3];
    reg [1:0] active_item, next_active_item;   // latched item index
    reg       paid_by_card, next_paid_by_card; // latched payment method for this txn
    reg [7:0] coin_value;
    reg [15:0] revenue, next_revenue;
    reg [7:0]  txn_count, next_txn_count;
    integer   sel_idx;
    integer   i;

    // ---------------- Change-making function (greedy: 20 -> 10 -> 5) ----------------
    function [11:0] make_change;
        input [7:0] amt;
        reg   [7:0] rem;
        begin
            rem = amt;
            make_change[11:8] = rem / 8'd20; rem = rem % 8'd20;
            make_change[7:4]  = rem / 8'd10; rem = rem % 8'd10;
            make_change[3:0]  = rem / 8'd5;
        end
    endfunction

    // ---------------- Combinational: next-state + datapath ----------------
    always @(*) begin
        sel_idx    = item_sel - 1;
        coin_value = coin_5  ? 8'd5  :
                     coin_10 ? 8'd10 :
                     coin_20 ? 8'd20 : 8'd0;

        // Defaults every cycle (avoids latches)
        next_state        = state;
        next_amount        = amount;
        next_idle_timer    = idle_timer;
        next_active_item   = active_item;
        next_paid_by_card  = paid_by_card;
        next_revenue       = revenue;
        next_txn_count     = txn_count;
        for (i = 0; i < 4; i = i + 1) next_stock[i] = stock[i];

        dispense          = 4'b0000;
        sold_out_flag     = 4'b0000;
        insufficient_flag = 1'b0;
        card_txn_flag     = 1'b0;
        change_20 = 4'd0; change_10 = 4'd0; change_5 = 4'd0;

        case (state)
            IDLE: begin
                if (cancel && amount > 0) begin
                    next_state = REFUND;
                end else if (item_sel != 3'b000) begin
                    if (stock[sel_idx] == 2'd0) begin
                        next_state       = SOLD_OUT;
                        next_active_item = sel_idx;
                    end else if (card_pay && amount == 0) begin
                        // Card/UPI path: external terminal already approved exact payment
                        next_state        = DISPENSE;
                        next_active_item  = sel_idx;
                        next_paid_by_card = 1'b1;
                    end else if (amount >= price[sel_idx]) begin
                        next_state        = DISPENSE;
                        next_active_item  = sel_idx;
                        next_paid_by_card = 1'b0;
                    end else begin
                        next_state = INSUFFICIENT;
                    end
                end else if (coin_value != 0) begin
                    next_amount     = amount + coin_value;
                    next_idle_timer = 8'd0;
                end else if (amount > 0) begin
                    next_idle_timer = idle_timer + 8'd1;
                    if (idle_timer + 1 >= TIMEOUT_CYCLES)
                        next_state = REFUND;
                end
            end

            INSUFFICIENT: begin
                insufficient_flag = 1'b1;
                if (coin_value != 0) begin
                    next_amount     = amount + coin_value;
                    next_idle_timer = 8'd0;
                end
                next_state = IDLE;
            end

            SOLD_OUT: begin
                sold_out_flag[active_item] = 1'b1;
                if (coin_value != 0) begin
                    next_amount     = amount + coin_value;
                    next_idle_timer = 8'd0;
                end
                next_state = IDLE;
            end

            DISPENSE: begin
                dispense[active_item]   = 1'b1;
                next_stock[active_item] = stock[active_item] - 2'd1;
                next_revenue             = revenue + price[active_item];
                next_txn_count           = txn_count + 8'd1;

                if (paid_by_card) begin
                    card_txn_flag = 1'b1;
                    // exact payment already collected by the card terminal -> no change
                end else begin
                    {change_20, change_10, change_5} = make_change(amount - price[active_item]);
                end

                next_amount       = coin_value;  // start fresh; don't drop a coin this cycle
                next_idle_timer   = 8'd0;
                next_paid_by_card = 1'b0;
                next_state        = IDLE;
            end

            REFUND: begin
                {change_20, change_10, change_5} = make_change(amount);
                next_amount     = coin_value;    // start fresh; don't drop a coin this cycle
                next_idle_timer = 8'd0;
                next_state      = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // ---------------- Sequential: register updates ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            amount       <= 8'd0;
            idle_timer   <= 8'd0;
            active_item  <= 2'd0;
            paid_by_card <= 1'b0;
            revenue      <= 16'd0;
            txn_count    <= 8'd0;
            for (i = 0; i < 4; i = i + 1) stock[i] <= INIT_STOCK[1:0];
        end else begin
            state        <= next_state;
            amount       <= next_amount;
            idle_timer   <= next_idle_timer;
            active_item  <= next_active_item;
            paid_by_card <= next_paid_by_card;
            revenue      <= next_revenue;
            txn_count    <= next_txn_count;
            for (i = 0; i < 4; i = i + 1) stock[i] <= next_stock[i];
        end
    end

    assign amount_disp   = amount;
    assign stock_disp    = {stock[3], stock[2], stock[1], stock[0]};
    assign total_revenue = revenue;
    assign total_txns    = txn_count;

endmodule
