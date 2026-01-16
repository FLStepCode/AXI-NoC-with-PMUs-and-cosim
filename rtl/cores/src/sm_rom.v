/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

`define SIM

`ifdef SIM
    `define PATH ""
`else
    `define PATH "./modelsim/"
`endif

`define SINGLE_CORE

module sm_rom
#(
    parameter SIZE = 128,
    NODE_ID = 0
) (
    input  [31:0] a,
    output [31:0] rd
);

    reg [31:0] rom [SIZE - 1:0];
    assign rd = rom [a];

    initial begin

        `ifdef TEST

            rom[0] = 32'h61400293;
            rom[1] = 32'h08000313;
            rom[2] = 32'h00532023;
            rom[3] = 32'h00032383;
            rom[4] = 32'h00000063;
            
        `else
            if (NODE_ID == 0) begin
                $readmemh({`PATH, "instr_node_0.hex"}, rom);
            end
            else if (NODE_ID == 1) begin
                $readmemh({`PATH, "instr_node_1.hex"}, rom);
            end
            else if (NODE_ID == 2) begin
                $readmemh({`PATH, "instr_node_2.hex"}, rom);
            end
            else if (NODE_ID == 3) begin
                $readmemh({`PATH, "instr_node_3.hex"}, rom);
            end
            else if (NODE_ID == 4) begin
                $readmemh({`PATH, "instr_node_4.hex"}, rom);
            end
            else if (NODE_ID == 5) begin
                $readmemh({`PATH, "instr_node_5.hex"}, rom);
            end
            else if (NODE_ID == 6) begin
                $readmemh({`PATH, "instr_node_6.hex"}, rom);
            end
            else if (NODE_ID == 7) begin
                $readmemh({`PATH, "instr_node_7.hex"}, rom);
            end
            else if (NODE_ID == 8) begin
                $readmemh({`PATH, "instr_node_8.hex"}, rom);
            end
            else if (NODE_ID == 9) begin
                $readmemh({`PATH, "instr_node_9.hex"}, rom);
            end
            else if (NODE_ID == 10) begin
                $readmemh({`PATH, "instr_node_10.hex"}, rom);
            end
            else if (NODE_ID == 11) begin
                $readmemh({`PATH, "instr_node_11.hex"}, rom);
            end
            else if (NODE_ID == 12) begin
                $readmemh({`PATH, "instr_node_12.hex"}, rom);
            end
            else if (NODE_ID == 13) begin
                $readmemh({`PATH, "instr_node_13.hex"}, rom);
            end
            else if (NODE_ID == 14) begin
                $readmemh({`PATH, "instr_node_14.hex"}, rom);
            end
            else if (NODE_ID == 15) begin
                $readmemh({`PATH, "instr_node_15.hex"}, rom);
            end

        `endif

    end
endmodule