`timescale 1ns/1ps
module tb_async_fifo_4x4;
    // Clocks
    reg wr_clk = 0;
    reg rd_clk = 0;

    // Stimulus + DUT IO
    reg        rst_n = 0;
    reg        wr_en = 0;
    reg        rd_en = 0;
    reg  [3:0] din   = 4'h0;
    wire [3:0] dout;
    wire       full, empty;

    // Instantiate DUT
    async_fifo_4x4 dut (
        .wr_clk (wr_clk),
        .rd_clk (rd_clk),
        .rst_n  (rst_n),
        .wr_en  (wr_en),
        .rd_en  (rd_en),
        .din    (din),
        .dout   (dout),
        .full   (full),
        .empty  (empty)
    );

    // Generate asynchronous clocks (different rates)
    // wr_clk = 100 MHz (10 ns), rd_clk ~71.4 MHz (14 ns)
    always #5  wr_clk = ~wr_clk;
    always #7  rd_clk = ~rd_clk;

    // Simple scoreboard variables
    reg [3:0] exp_mem [0:3];
    integer wcnt, rcnt;
    integer errors;

    initial begin
        $display("[%0t] TB start", $time);
        errors = 0;
        wcnt = 0; rcnt = 0;

        // Reset
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        din   = 0;
        repeat (4) @(posedge wr_clk);
        rst_n = 1;
        $display("[%0t] Deassert reset", $time);

        // ----------------------------
        // WRITE PHASE: push 4 values
        // ----------------------------
        // Use a small gap pattern to not align with rd_clk edges.
        fork
            begin : WRITE_THREAD
                @(posedge wr_clk);
                repeat (4) begin
                    @(posedge wr_clk);
                    if (full) begin
                        $display("[%0t] WARNING: FIFO full before write %0d", $time, wcnt);
                    end
                    wr_en <= 1;
                    din   <= (wcnt + 4'hA) & 4'hF; // some pattern: A,B,C,D
                    exp_mem[wcnt] = ((wcnt + 4'hA) & 4'hF);
                    @(posedge wr_clk);
                    wr_en <= 0;
                    wcnt  = wcnt + 1;
                end
            end
            begin : READ_THREAD
                // Start reading a bit later to allow fill, then read all 4
                repeat (6) @(posedge rd_clk);
                repeat (4) begin
                    @(posedge rd_clk);
                    if (empty) begin
                        // wait until not empty to capture valid data
                        wait (!empty);
                    end
                    rd_en <= 1;
                    @(posedge rd_clk);
                    rd_en <= 0;
                    // Check after a small delta to allow dout capture
                    #0.1;
                    if (dout !== exp_mem[rcnt]) begin
                        $display("[%0t] ERROR: Read %0d got 0x%0h expected 0x%0h",
                                 $time, rcnt, dout, exp_mem[rcnt]);
                        errors = errors + 1;
                    end else begin
                        $display("[%0t] Read %0d OK: 0x%0h", $time, rcnt, dout);
                    end
                    rcnt = rcnt + 1;
                end
            end
        join

        // Final result
        if (errors == 0) begin
            $display("\n============================");
            $display(" TEST PASS: Data matches! ");
            $display("============================\n");
        end else begin
            $display("\n============================");
            $display(" TEST FAIL: %0d error(s).", errors);
            $display("============================\n");
        end

        // Let a few cycles run for waveform clarity
        repeat (5) @(posedge wr_clk);
        $finish;
    end

    initial begin
        $dumpfile("tb_async_fifo_4x4.vcd");
        $dumpvars(0, tb_async_fifo_4x4);
    end
endmodule
