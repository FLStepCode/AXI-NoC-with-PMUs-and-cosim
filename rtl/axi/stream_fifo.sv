module stream_fifo #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_LEN = 16
) (
    input logic ACLK,
    input logic ARESETn,
    
    input  axis_mosi_t in_mosi_i,
    output axis_miso_t in_miso_o,
    output axis_mosi_t out_mosi_o,
    input  axis_miso_t out_miso_i
    
);
    localparam ADDR_WIDTH = $clog2(FIFO_LEN);

    logic [DATA_WIDTH-1:0] fifo_mem [FIFO_LEN];
    logic [ADDR_WIDTH-1:0] read_ptr, read_ptr_reg;
    logic [ADDR_WIDTH-1:0] write_ptr;
    logic [ADDR_WIDTH:0] count;

    assign data_o = fifo_mem[read_ptr];

    assign out_mosi_o.TVALID = (count > 0);
    assign out_miso_i.TREADY = !(count == FIFO_LEN);

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_ptr <= 0;
            write_ptr <= 0;
            count <= 0;
        end
        else begin
            if (in_mosi_i.TVALID && out_miso_i.TREADY) begin
                write_ptr <= (write_ptr == (FIFO_LEN - 1)) ? 0 : write_ptr + 1;
            end
            if (out_mosi_o.TVALID && in_miso_o.TREADY) begin
                read_ptr <= (read_ptr == (FIFO_LEN - 1)) ? 0 : read_ptr + 1;
            end

            if (in_mosi_i.TVALID && out_miso_i.TREADY && !(out_mosi_o.TVALID && in_miso_o.TREADY)) begin
                count <= count + 1;
            end
            else if (!(in_mosi_i.TVALID && out_miso_i.TREADY) && (out_mosi_o.TVALID && in_miso_o.TREADY)) begin
                count <= count - 1;
            end
        end
    end

    always @(posedge ACLK) begin
        if (in_mosi_i.TVALID && out_miso_i.TREADY) begin
            fifo_mem[write_ptr] <= data_i;
        end
    end
    /*
    logic write_handshake;

    assign out_miso_i.TREADY = !((count != 0) & (read_ptr_reg == write_ptr));
	assign out_mosi_o.TVALID = (count > 0);

    always @(posedge ACLK) begin
        if (in_mosi_i.TVALID && out_miso_i.TREADY) begin
            fifo_mem[write_ptr] <= data_i;
        end
    end
    
    always @(posedge ACLK) begin
        data_o <= fifo_mem[read_ptr];
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_ptr_reg <= 0;
            write_ptr <= 0;
            write_handshake <= 0;
        end
        else begin
            if (in_mosi_i.TVALID && out_miso_i.TREADY) begin
                write_ptr <= (write_ptr == (FIFO_LEN - 1)) ? 0 : write_ptr + 1;
            end

            read_ptr_reg <= read_ptr;
            write_handshake <= in_mosi_i.TVALID & out_miso_i.TREADY;
        end
    end

    always_comb begin
        read_ptr = read_ptr_reg;
        if (out_mosi_o.TVALID && in_miso_o.TREADY) begin
            read_ptr = (read_ptr_reg == (FIFO_LEN - 1)) ? 0 : read_ptr_reg + 1;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            count <= 0;
        end
        else begin
				
            if (write_handshake && !(out_mosi_o.TVALID && in_miso_o.TREADY)) begin
                count <= count + 1;
            end

            if (!write_handshake && (out_mosi_o.TVALID && in_miso_o.TREADY)) begin
                count <= count - 1;
            end
        end
    end
    */
endmodule