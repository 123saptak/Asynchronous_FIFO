
module async_fifo_4x4 (
    input  wire        wr_clk,
    input  wire        rd_clk,
    input  wire        rst_n,      // active-low async reset (OK for FPGAs too)
    input  wire        wr_en,      // write request
    input  wire        rd_en,      // read request
    input  wire [3:0]  din,        // data in (4 bits)
    output reg  [3:0]  dout,       // data out (4 bits)
    output wire        full,
    output wire        empty
);
    localparam WIDTH = 4;
    localparam DEPTH = 4;
    localparam ADDR  = $clog2(DEPTH);      // 2
    localparam PWB   = ADDR + 1;           // pointer width incl wrap bit (3)

    // ------------------------------------------------------------
    // Storage
    // ------------------------------------------------------------
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // ------------------------------------------------------------
    // Binary & Gray pointers in write domain
    // ------------------------------------------------------------
    reg  [PWB-1:0] wptr_bin, wptr_gray;
    wire [PWB-1:0] wptr_bin_nxt = wptr_bin + (wr_en & ~full);
    wire [PWB-1:0] wptr_gray_nxt = (wptr_bin_nxt >> 1) ^ wptr_bin_nxt;

    // ------------------------------------------------------------
    // Binary & Gray pointers in read domain
    // ------------------------------------------------------------
    reg  [PWB-1:0] rptr_bin, rptr_gray;
    wire [PWB-1:0] rptr_bin_nxt = rptr_bin + (rd_en & ~empty);
    wire [PWB-1:0] rptr_gray_nxt = (rptr_bin_nxt >> 1) ^ rptr_bin_nxt;

    // ------------------------------------------------------------
    // Cross-domain synchronizers (2-FF) for Gray pointers
    // ------------------------------------------------------------
    reg [PWB-1:0] rptr_gray_sync_w1, rptr_gray_sync_w2;
    reg [PWB-1:0] wptr_gray_sync_r1, wptr_gray_sync_r2;

    // ------------------------------------------------------------
    // FULL logic (compare next write Gray to read Gray synced into wr_clk)
    // Full when next write pointer == synced read pointer with MSBs inverted
    // (classic async FIFO technique)
    // ------------------------------------------------------------
    wire [PWB-1:0] rptr_gray_wr = rptr_gray_sync_w2;
    wire full_nxt = (wptr_gray_nxt == {~rptr_gray_wr[PWB-1:PWB-2], rptr_gray_wr[PWB-3:0]});

    // ------------------------------------------------------------
    // EMPTY logic (compare read Gray to write Gray synced into rd_clk)
    // Empty when next read pointer equals synced write pointer
    // ------------------------------------------------------------
    wire [PWB-1:0] wptr_gray_rd = wptr_gray_sync_r2;
    wire empty_nxt = (rptr_gray_nxt == wptr_gray_rd);

    reg full_r, empty_r;
    assign full  = full_r;
    assign empty = empty_r;

    // ------------------------------------------------------------
    // Write domain sequential logic
    // ------------------------------------------------------------
    integer widx;
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr_bin  <= 1'b0;
            wptr_gray <= 1'b0;
            full_r    <= 1'b0;
            // memory reset not required for synthesis correctness
        end else begin
            // Write to RAM
            if (wr_en && ~full_r) begin
                mem[wptr_bin[ADDR-1:0]] <= din;
            end
            // Update pointers + full
            wptr_bin  <= wptr_bin_nxt;
            wptr_gray <= wptr_gray_nxt;
            full_r    <= full_nxt;
        end
    end

    // Sync read Gray into write domain
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr_gray_sync_w1 <= 1'b0;
            rptr_gray_sync_w2 <= 1'b0;
        end else begin
            rptr_gray_sync_w1 <= rptr_gray;
            rptr_gray_sync_w2 <= rptr_gray_sync_w1;
        end
    end

    // ------------------------------------------------------------
    // Read domain sequential logic
    // ------------------------------------------------------------
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr_bin  <= 1'b0;
            rptr_gray <= 1'b0;
            dout      <= 1'b0;
            empty_r   <= 1'b1;
        end else begin
            // Read from RAM
            if (rd_en && ~empty_r) begin
                dout <= mem[rptr_bin[ADDR-1:0]];
            end
            // Update pointers + empty
            rptr_bin  <= rptr_bin_nxt;
            rptr_gray <= rptr_gray_nxt;
            empty_r   <= empty_nxt;
        end
    end

    // Sync write Gray into read domain
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr_gray_sync_r1 <= 1'b0;
            wptr_gray_sync_r2 <= 1'b0;
        end else begin
            wptr_gray_sync_r1 <= wptr_gray;
            wptr_gray_sync_r2 <= wptr_gray_sync_r1;
        end
    end

endmodule
