module cosim_top #(
    parameter CORE_COUNT    = 16,
    parameter AXI_ID_WIDTH  = 5,
    parameter BAUD_RATE     = 9_600,
    parameter CLK_FREQ      = 50_000_000
) (
    input  logic clk_i,
    input  logic arstn_i,
    input  logic rx_i,
    output logic tx_o
);

    logic [4:0]              pmu_addr   [CORE_COUNT];
    logic [31:0]             pmu_data   [CORE_COUNT];
    logic                    resp_wait  [CORE_COUNT];
    logic [AXI_ID_WIDTH-1:0] id         [CORE_COUNT];
    logic                    write      [CORE_COUNT];
    logic [7:0]              axlen      [CORE_COUNT];
    logic                    fifo_push  [CORE_COUNT];
    logic                    start                  ;
    logic                    idle       [CORE_COUNT];

    mesh_with_loaders mesh_with_loaders (
        .aclk        (clk_i),
        .aresetn     (arstn_i),

        .pmu_addr_i  (pmu_addr ),
        .pmu_data_o  (pmu_data ),

        .resp_wait_i (resp_wait),
        .id_i        (id       ),
        .write_i     (write    ),
        .axlen_i     (axlen    ),
        .fifo_push_i (fifo_push),
        .start_i     (start    ),
        .idle_o      (idle     )      
    );

    uart_control #(
        .CORE_COUNT   (CORE_COUNT  ),
        .AXI_ID_WIDTH (AXI_ID_WIDTH),
        .BAUD_RATE    (BAUD_RATE   ),
        .CLK_FREQ     (CLK_FREQ    )
    ) uart_control (
        .clk_i        (clk_i),
        .arstn_i      (arstn_i),
        .rx_i         (rx_i),
        .tx_o         (tx_o),

        .pmu_addr_o   (pmu_addr ),
        .pmu_data_i   (pmu_data ),

        .resp_wait_o  (resp_wait),
        .id_o         (id       ),
        .write_o      (write    ),
        .axlen_o      (axlen    ),
        .fifo_push_o  (fifo_push),
        .start_o      (start    ),
        .idle_i       (idle     )
    );
    
endmodule