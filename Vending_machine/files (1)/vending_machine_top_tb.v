`timescale 1ns/1ps

module vending_machine_top_tb;

    reg clk, rst_n;
    reg coin_5_raw, coin_10_raw, coin_20_raw;
    reg [2:0] item_sel;
    reg cancel, card_pay;
    wire [3:0] dispense, sold_out_flag;
    wire insufficient_flag, card_txn_flag;
    wire [3:0] change_20, change_10, change_5;
    wire [7:0] amount_disp, stock_disp;
    wire [15:0] total_revenue;
    wire [7:0] total_txns;
    integer i, errors, k, found;

    vending_machine_top #(.TIMEOUT_CYCLES(30), .DEBOUNCE_CYCLES(4)) dut (
        .clk(clk), .rst_n(rst_n),
        .coin_5_raw(coin_5_raw), .coin_10_raw(coin_10_raw), .coin_20_raw(coin_20_raw),
        .item_sel(item_sel), .cancel(cancel), .card_pay(card_pay),
        .dispense(dispense), .sold_out_flag(sold_out_flag),
        .insufficient_flag(insufficient_flag), .card_txn_flag(card_txn_flag),
        .change_20(change_20), .change_10(change_10), .change_5(change_5),
        .amount_disp(amount_disp), .stock_disp(stock_disp),
        .total_revenue(total_revenue), .total_txns(total_txns)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Clean, well-formed coin insertion (held stable long enough to clear
    // the synchronizer + debounce filter with margin)
    task insert_coin;
        input integer val;
        begin
            coin_5_raw = 0; coin_10_raw = 0; coin_20_raw = 0;
            if (val == 5)  coin_5_raw  = 1;
            if (val == 10) coin_10_raw = 1;
            if (val == 20) coin_20_raw = 1;
            repeat (10) @(posedge clk);
            coin_5_raw = 0; coin_10_raw = 0; coin_20_raw = 0;
            repeat (4) @(posedge clk);
        end
    endtask

    task select_item;
        input [2:0] sel;
        begin
            item_sel = sel;
            @(posedge clk);
            item_sel = 3'b000;
        end
    endtask

    task check;
        input cond;
        input [8*48:1] msg;
        begin
            if (!cond) begin
                $display("*** CHECK FAILED at time %0t: %s ***", $time, msg);
                errors = errors + 1;
            end else begin
                $display("    CHECK PASSED at time %0t: %s", $time, msg);
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 0; item_sel = 0; cancel = 0; card_pay = 0;
        coin_5_raw = 0; coin_10_raw = 0; coin_20_raw = 0;
        #12; rst_n = 1;

        // ---------- Test 1: normal purchase with change ----------
        insert_coin(10); insert_coin(10);
        select_item(3'b001);
        #1; check(change_5 == 1 && change_10 == 0 && change_20 == 0,
                   "Test1: expected change of Rs5 for Potato Chips");
        #10;

        // ---------- Test 2: insufficient, then success ----------
        insert_coin(10);
        select_item(3'b010);
        #1; check(insufficient_flag == 1, "Test2a: expected insufficient_flag");
        insert_coin(20);
        select_item(3'b010);
        #1; check(dispense[1] == 1 && change_5 == 1,
                   "Test2b: expected dispense Cold Drink with Rs5 change");
        #10;

        // ---------- Test 3: cancel -> full refund ----------
        insert_coin(20);
        cancel = 1; @(posedge clk); cancel = 0;
        #1; check(change_20 == 1, "Test3: expected refund of Rs20 on cancel");
        #10;

        // ---------- Test 4: exhaust Mineral Water stock, then sold out ----------
        for (i = 0; i < 3; i = i + 1) begin
            insert_coin(10);
            select_item(3'b011);
        end
        insert_coin(10);
        select_item(3'b011);
        #1; check(sold_out_flag[2] == 1, "Test4: expected sold_out_flag on Mineral Water");
        #10;

        // ---------- Test 5: idle timeout auto-refund ----------
        cancel = 1; @(posedge clk); cancel = 0; #10;
        insert_coin(5);
        found = 0;
        for (k = 0; k < 45 && !found; k = k + 1) begin
            @(posedge clk); #1;
            if (change_5 || change_10 || change_20) begin
                check(change_5 == 1 && change_10 == 0 && change_20 == 0,
                      "Test5: expected timeout auto-refund of Rs5");
                found = 1;
            end
        end
        if (!found) begin
            errors = errors + 1;
            $display("*** CHECK FAILED: Test5: timeout refund never occurred ***");
        end
        #10;

        // ---------- Test 6: card / UPI payment (no coins, no change) ----------
        card_pay = 1; select_item(3'b100); card_pay = 0;  // Chocolate Bar, Rs20 via card
        #1; check(dispense[3] == 1 && card_txn_flag == 1 &&
                   change_5 == 0 && change_10 == 0 && change_20 == 0,
                   "Test6: expected card-paid dispense of Chocolate Bar with no change");
        #10;

        // ---------- Test 7: coin debounce rejects a noisy/bouncy signal ----------
        begin : debounce_test
            reg [7:0] amount_before;
            amount_before = amount_disp;
            // Simulate a bouncy mechanical sensor: rapid glitches before settling high
            coin_5_raw = 1; @(posedge clk);
            coin_5_raw = 0; @(posedge clk);
            coin_5_raw = 1; @(posedge clk);
            coin_5_raw = 1; @(posedge clk);
            coin_5_raw = 0; @(posedge clk);
            coin_5_raw = 1; @(posedge clk);
            // now settle cleanly high long enough to pass the debounce filter
            repeat (10) @(posedge clk);
            coin_5_raw = 0;
            repeat (6) @(posedge clk);
            #1;
            check(amount_disp == amount_before + 8'd5,
                  "Test7: bouncy input must register as exactly one Rs5 coin");
        end
        #10;

        // ---------- Test 8: revenue and transaction counters ----------
        // By this point: Test1 (Potato Chips, Rs15), Test2b (Cold Drink, Rs25),
        // Test4 (Mineral Water x3, Rs10 each = Rs30), Test6 (Chocolate Bar, Rs20)
        // Total transactions = 1 + 1 + 3 + 1 = 6
        // Total revenue = 15 + 25 + 30 + 20 = Rs90
        #1; check(total_revenue == 16'd90, "Test8a: expected total_revenue = Rs90");
        check(total_txns == 8'd6, "Test8b: expected total_txns = 6");

        #20;
        if (errors == 0)
            $display("\nALL CHECKS PASSED. Simulation complete.");
        else
            $display("\n%0d CHECK(S) FAILED. Simulation complete.", errors);
        $finish;
    end

endmodule
