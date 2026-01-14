module mesh_with_loaders (
    input  logic        aclk,
    input  logic        aresetn,

    input  logic [4:0]  pmu_addr_i   [16],
    output logic [31:0] pmu_data_o   [16],

    input  logic        resp_wait_i  [16],
    input  logic [4:0]  id_i         [16],
    input  logic        write_i      [16],
    input  logic [7:0]  axlen_i      [16],
    input  logic        fifo_push_i  [16],
    input  logic        start_i,
    output logic        idle_o       [16]
);

    axi_if #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(8),
        .ID_W_WIDTH(5),
        .ID_R_WIDTH(5)
    ) axi[16](), axi_ram[16]();

    generate
        genvar i;
        for (i = 0; i < 16; i++) begin : map_wires

            axi_pmu pmu (
                .aclk    (aclk),
                .aresetn (aresetn),
                .mon_axi (axi[i]),
                .addr_i  (pmu_addr_i[i]),
                .data_o  (pmu_data_o[i])
            );

            axi_master_loader #(
                .DATA_WIDTH(8),
                .ADDR_WIDTH(8),
                .ID_W_WIDTH(5),
                .ID_R_WIDTH(5),
                .LOADER_ID (i)
            ) loader (
                .clk_i       (aclk),
                .arstn_i     (aresetn),
                .resp_wait_i (resp_wait_i[i]),
                .id_i        (id_i[i]),
                .write_i     (write_i[i]),
                .axlen_i     (axlen_i[i]),
                .fifo_push_i (fifo_push_i[i]),
                .start_i     (start_i),
                .idle_o      (idle_o[i]),
                .m_axi_o     (axi[i])
            );
        end
    endgenerate

    XY_mesh_dual_parallel #(
        .ADDR_WIDTH(8)
    ) dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_in(axi),
        .m_axi_out(axi_ram)
    );

    generate
        for (i = 0; i < 16; i++) begin : map_rams
            axi_ram #(
                .DATA_WIDTH(8),
                .ADDR_WIDTH(8),
                .ID_W_WIDTH(5),
                .ID_R_WIDTH(5)
            ) ram (
                .clk(aclk),
                .rst_n(aresetn),
                .axi_s(axi_ram[i])
            );
        end

    endgenerate
    
endmodule