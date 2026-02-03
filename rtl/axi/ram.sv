module ram #(
    parameter ADDR_WIDTH  = 16,
    parameter BYTE_WIDTH  = 8
) (
    input clk_i,

    // Port a 
    input  logic [ADDR_WIDTH-1:0] waddr, raddr,
    input  logic [BYTE_WIDTH-1:0] wdata,
    input  logic we,
    output logic [BYTE_WIDTH-1:0] rdata
);

    logic [BYTE_WIDTH-1:0] ram [2**ADDR_WIDTH];

    always_ff @( posedge clk_i ) begin : ram_a
        if(we) begin
            ram[waddr] <= wdata;
        end
        rdata <= ram[raddr];
    end

endmodule: ram