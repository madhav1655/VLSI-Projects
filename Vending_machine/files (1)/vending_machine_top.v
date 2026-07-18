`timescale 1ns/1ps
// =============================================================
// Vending Machine - Top Level
// Wraps the core FSM/datapath with coin debouncers so that raw,
// noisy/bouncy sensor inputs can be connected directly to this
// module's coin_5_raw/coin_10_raw/coin_20_raw ports.
// card_pay is NOT debounced here: it is expected to arrive as a
// single clean pulse from an external, already-digital payment
// terminal (card/UPI reader), not a mechanical sensor.
// =============================================================
module vending_machine_top #(
    parameter INIT_STOCK       = 3,
    parameter TIMEOUT_CYCLES   = 20,
    parameter DEBOUNCE_CYCLES  = 4
)(
    input                clk,
    input                rst_n,
    input                coin_5_raw,
    input                coin_10_raw,
    input                coin_20_raw,
    input        [2:0]   item_sel,
    input                cancel,
    input                card_pay,

    output       [3:0]   dispense,
    output       [3:0]   sold_out_flag,
    output               insufficient_flag,
    output               card_txn_flag,
    output       [3:0]   change_20,
    output       [3:0]   change_10,
    output       [3:0]   change_5,
    output       [7:0]   amount_disp,
    output       [7:0]   stock_disp,
    output       [15:0]  total_revenue,
    output       [7:0]   total_txns
);

    wire coin_5_clean, coin_10_clean, coin_20_clean;

    debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db5 (
        .clk(clk), .rst_n(rst_n), .noisy_in(coin_5_raw),  .clean_pulse(coin_5_clean)
    );
    debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db10 (
        .clk(clk), .rst_n(rst_n), .noisy_in(coin_10_raw), .clean_pulse(coin_10_clean)
    );
    debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db20 (
        .clk(clk), .rst_n(rst_n), .noisy_in(coin_20_raw), .clean_pulse(coin_20_clean)
    );

    vending_machine_premium #(
        .INIT_STOCK(INIT_STOCK), .TIMEOUT_CYCLES(TIMEOUT_CYCLES)
    ) core (
        .clk(clk), .rst_n(rst_n),
        .coin_5(coin_5_clean), .coin_10(coin_10_clean), .coin_20(coin_20_clean),
        .item_sel(item_sel), .cancel(cancel), .card_pay(card_pay),
        .dispense(dispense), .sold_out_flag(sold_out_flag),
        .insufficient_flag(insufficient_flag), .card_txn_flag(card_txn_flag),
        .change_20(change_20), .change_10(change_10), .change_5(change_5),
        .amount_disp(amount_disp), .stock_disp(stock_disp),
        .total_revenue(total_revenue), .total_txns(total_txns)
    );

endmodule
