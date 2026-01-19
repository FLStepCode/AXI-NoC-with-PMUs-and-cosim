`timescale 1ns/1ps

module tb_cpu (
    input  logic        rst_n
);

    logic clk;

    parameter AXI_DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 16;
    parameter ID_W_WIDTH = 5;
    parameter ID_R_WIDTH = 5;
    parameter MAX_ID_WIDTH = 4;
    parameter ID_WIDTH = 4;
    parameter DEST_WIDTH = 4;
    parameter USER_WIDTH = 4;

    `include "axi_type.svh"

    axi_miso_t axi_miso;
    axi_mosi_t axi_mosi;

    sr_cpu_axi #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .MAX_ID_WIDTH(MAX_ID_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
        `ifdef TID_PRESENT
            ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
            ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
            ,
        .USER_WIDTH(USER_WIDTH)
        `endif
    ) cpu (
        .clk   (clk),  
        .rst_n (rst_n),

        .in_miso_i(axi_miso),
        .in_mosi_o(axi_mosi)
    );

    axi_ram #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH)
        `ifdef TID_PRESENT
         ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
         ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
         ,
        .USER_WIDTH(USER_WIDTH)
        `endif
    ) ram (
        .clk_i   (clk),
        .rst_n_i (rst_n),
        
        .in_mosi_i(axi_mosi),
        .in_miso_o(axi_miso)
    );

    always #1 clk = !clk;

    initial begin
        $readmemh("single_core.hex", cpu.instr.rom);
        $readmemh("single_image.hex", ram.coupled_ram.ram);

        clk = 1;
    end
    
endmodule