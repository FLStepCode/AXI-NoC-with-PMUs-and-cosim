module axi_master_loader #(
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 16,
    parameter ID_W_WIDTH   = 5,
    parameter ID_R_WIDTH   = 5,
    parameter FIFO_DEPTH   = 32,
    parameter LOADER_ID    = 0,

    parameter MAX_ID_WIDTH = (ID_W_WIDTH > ID_R_WIDTH) ? ID_W_WIDTH : ID_R_WIDTH
) (
    input  logic                    clk_i,
    input  logic                    arstn_i,

    input  logic                    resp_wait_i,
    input  logic [MAX_ID_WIDTH-1:0] id_i,
    input  logic                    write_i,
    input  logic [7:0]              axlen_i,
    input  logic                    fifo_push_i,

    input  logic                    start_i,
    output logic                    idle_o,
    axi_if.m                        m_axi_o
);

    typedef enum logic[1:0] {
        IDLE,
        MOSI,
        MISO
    } states_t;

    states_t state_w, state_w_next;
    states_t state_r, state_r_next;


    logic [MAX_ID_WIDTH-1:0] awid_rd, arid_rd;
    logic [7:0] awlen_rd, arlen_rd;
    logic w_resp_wait_rd, r_resp_wait_rd;
    logic w_fifo_valid_rd, w_fifo_ready_rd, r_fifo_valid_rd, r_fifo_ready_rd;
    
    logic [7:0] w_hand_counter;
    logic [7:0] b_wait_cnt, b_wait_cnt_next, r_wait_cnt, r_wait_cnt_next;

    logic w_idle, r_idle;

    logic awlen_fifo_valid_rd, awlen_fifo_ready_rd;
    logic awlen_resp_wait_rd, awlen_wait;
    logic [7:0] awlen_current;


    assign m_axi_o.AWID    = awid_rd;
    assign m_axi_o.AWADDR  = LOADER_ID << 2;
    assign m_axi_o.AWLEN   = awlen_rd;
    assign m_axi_o.AWSIZE  = $clog2(DATA_WIDTH/8);
    assign m_axi_o.AWBURST = 2'b01;

    assign m_axi_o.WDATA   = 'h30 + LOADER_ID;
    assign m_axi_o.WSTRB   = '1;

    assign m_axi_o.BREADY  = 1'b1;

    assign m_axi_o.ARID    = arid_rd;
    assign m_axi_o.ARADDR  = LOADER_ID << 2;
    assign m_axi_o.ARLEN   = arlen_rd;
    assign m_axi_o.ARSIZE  = $clog2(DATA_WIDTH/8);
    assign m_axi_o.ARBURST = 2'b01;

    assign m_axi_o.RREADY = 1'b1;

    assign idle_o = w_idle & r_idle;


    /* --- W SECTION --- */

    stream_fifo #(
        .DATA_WIDTH (MAX_ID_WIDTH + 1 + 8),
        .FIFO_LEN   (FIFO_DEPTH)
    ) u_stream_fifo_w (
        .ACLK    (clk_i),
        .ARESETn (arstn_i),

        .data_i  ({resp_wait_i, axlen_i, id_i}),
        .valid_i (fifo_push_i & write_i),
        .ready_o (), // NC

        .data_o  ({w_resp_wait_rd, awlen_rd, awid_rd}),
        .valid_o (w_fifo_valid_rd),
        .ready_i (w_fifo_ready_rd)
    );

    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (!arstn_i) begin
            state_w <= IDLE;
            b_wait_cnt <= '0;
        end
        else begin
            state_w <= state_w_next;
            b_wait_cnt <= b_wait_cnt_next;
        end
    end

    always_comb begin
        case (state_w)
            IDLE: begin
                if (w_fifo_valid_rd && start_i) begin
                    state_w_next = MOSI;
                end
                else begin
                    state_w_next = IDLE; 
                end
            end
            MOSI: begin
                if (!w_fifo_valid_rd || (m_axi_o.AWVALID && m_axi_o.AWREADY && w_resp_wait_rd)) begin
                    state_w_next = MISO;
                end
                else begin
                    state_w_next = MOSI;
                end
            end
            MISO: begin
                if (b_wait_cnt == 0) begin
                    if (w_fifo_valid_rd) begin
                        state_w_next = MOSI;
                    end
                    else begin
                        state_w_next = IDLE;
                    end
                end
                else begin
                    state_w_next = MISO;
                end
            end
            default: begin
            end
        endcase
    end

    always_comb begin
        w_idle = '0;
        w_fifo_ready_rd = '0;

        m_axi_o.AWVALID = '0;

        b_wait_cnt_next = b_wait_cnt;

        case (state_w)
            IDLE: begin
                w_idle = '1;
            end
            MOSI: begin
                w_fifo_ready_rd = m_axi_o.AWREADY;

                if (w_fifo_valid_rd) begin
                    m_axi_o.AWVALID = '1;
                end

                b_wait_cnt_next = b_wait_cnt + (m_axi_o.AWVALID & m_axi_o.AWREADY) - (m_axi_o.BVALID & m_axi_o.BREADY);
            end
            MISO: begin
                b_wait_cnt_next = b_wait_cnt + (m_axi_o.AWVALID & m_axi_o.AWREADY) - (m_axi_o.BVALID & m_axi_o.BREADY);
            end
            default: begin
            end
        endcase
    end

    stream_fifo #(
        .DATA_WIDTH (1 + 8),
        .FIFO_LEN   (FIFO_DEPTH)
    ) u_stream_fifo_awlen (
        .ACLK    (clk_i),
        .ARESETn (arstn_i),

        .data_i  ({resp_wait_i, axlen_i}),
        .valid_i (fifo_push_i & write_i),
        .ready_o (), // NC

        .data_o  ({awlen_resp_wait_rd, awlen_current}),
        .valid_o (awlen_fifo_valid_rd),
        .ready_i (awlen_fifo_ready_rd)
    );

    assign m_axi_o.WVALID = awlen_fifo_valid_rd & ~awlen_wait & (state_w != IDLE);
    assign m_axi_o.WLAST = (w_hand_counter == awlen_current);
    assign awlen_fifo_ready_rd = m_axi_o.WVALID & m_axi_o.WREADY & m_axi_o.WLAST;

    always_ff @(posedge clk_i or negedge arstn_i) begin : blockName
        if (!arstn_i) begin
            w_hand_counter <= '0;
            awlen_wait <= '0;
        end
        else begin
            if (m_axi_o.WVALID && m_axi_o.WREADY) begin
                if (w_hand_counter == awlen_current) begin
                    w_hand_counter <= '0;
                end
                else begin
                    w_hand_counter <= w_hand_counter + 1;
                end
            end

            awlen_wait <= (awlen_wait | (awlen_resp_wait_rd & m_axi_o.WVALID & m_axi_o.WREADY & m_axi_o.WLAST)) & (b_wait_cnt != 0);
        end
    end


    /* --- R SECTION --- */

    stream_fifo #(
        .DATA_WIDTH (MAX_ID_WIDTH + 1 + 8),
        .FIFO_LEN   (FIFO_DEPTH)
    ) u_stream_fifo_r (
        .ACLK    (clk_i),
        .ARESETn (arstn_i),

        .data_i  ({resp_wait_i, axlen_i, id_i}),
        .valid_i (fifo_push_i & ~write_i),
        .ready_o (), // NC

        .data_o  ({r_resp_wait_rd, arlen_rd, arid_rd}),
        .valid_o (r_fifo_valid_rd),
        .ready_i (r_fifo_ready_rd)
    );

    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (!arstn_i) begin
            state_r <= IDLE;
            r_wait_cnt <= '0;
        end
        else begin
            state_r <= state_r_next;
            r_wait_cnt <= r_wait_cnt_next;
        end
    end

    always_comb begin
        case (state_r)
            IDLE: begin
                if (r_fifo_valid_rd && start_i) begin
                    state_r_next = MISO;
                end
                else begin
                    state_r_next = IDLE; 
                end
            end
            MOSI: begin
                if (!r_fifo_valid_rd || (m_axi_o.ARVALID && m_axi_o.ARREADY && r_resp_wait_rd)) begin
                    state_r_next = MISO;
                end
                else begin
                    state_r_next = MOSI;
                end
            end
            MISO: begin
                if (r_wait_cnt == 0) begin
                    if (r_fifo_valid_rd) begin
                        state_r_next = MOSI;
                    end
                    else begin
                        state_r_next = IDLE;
                    end
                end
                else begin
                    state_r_next = MISO;
                end
            end
            default: begin
            end
        endcase
    end

    always_comb begin
        r_idle = '0;
        r_fifo_ready_rd = '0;

        m_axi_o.ARVALID = '0;

        r_wait_cnt_next = r_wait_cnt;

        case (state_r)
            IDLE: begin
                r_idle = '1;
            end
            MOSI: begin
                r_fifo_ready_rd = m_axi_o.ARREADY;

                if (r_fifo_valid_rd) begin
                    m_axi_o.ARVALID = '1;
                end

                r_wait_cnt_next = r_wait_cnt + (m_axi_o.ARVALID & m_axi_o.ARREADY) - (m_axi_o.RVALID & m_axi_o.RREADY & m_axi_o.RLAST);
            end
            MISO: begin
                r_wait_cnt_next = r_wait_cnt + (m_axi_o.ARVALID & m_axi_o.ARREADY) - (m_axi_o.RVALID & m_axi_o.RREADY & m_axi_o.RLAST);
            end
            default: begin
            end
        endcase
    end
    
endmodule