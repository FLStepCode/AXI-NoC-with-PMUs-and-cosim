module axi_pmu (
    input  logic aclk,
    input  logic aresetn,

    axi_if.mon mon_axi,

    input  logic [4:0]  addr_i,
    output logic [31:0] data_o
);

    typedef struct packed {
        logic [31:0] idle;
        logic [31:0] outstanding;
        logic [31:0] ar_stall;
        logic [31:0] ar_handshake;
        logic [31:0] rvalid_stall;
        logic [31:0] rready_stall;
        logic [31:0] r_handshake;
    } read_counters;

    typedef struct packed {
        logic [31:0] idle;
        logic [31:0] outstanding;
        logic [31:0] responding;
        logic [31:0] aw_stall;
        logic [31:0] aw_handshake;
        logic [31:0] wvalid_stall;
        logic [31:0] wready_stall;
        logic [31:0] w_handshake;
        logic [31:0] bvalid_stall;
        logic [31:0] bready_stall;
        logic [31:0] b_handshake;
    } write_counters;


    read_counters rc;
    write_counters wc;
    logic [31:0] clock_counter;

    always_comb begin
        case (addr_i)
            0:  data_o <= rc.idle;
            1:  data_o <= rc.outstanding;
            2:  data_o <= rc.ar_stall;
            3:  data_o <= rc.ar_handshake;
            4:  data_o <= rc.rvalid_stall;
            5:  data_o <= rc.rready_stall;
            6:  data_o <= rc.r_handshake;
            7:  data_o <= wc.idle;
            8:  data_o <= wc.outstanding;
            9:  data_o <= wc.responding;
            10: data_o <= wc.aw_stall;
            11: data_o <= wc.aw_handshake;
            12: data_o <= wc.wvalid_stall;
            13: data_o <= wc.wready_stall;
            14: data_o <= wc.w_handshake;
            15: data_o <= wc.bvalid_stall;
            16: data_o <= wc.bready_stall;
            17: data_o <= wc.b_handshake;
            18: data_o <= clock_counter;
            default: data_o <= '0;
        endcase
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            clock_counter <= 0;
        end
        else begin
            clock_counter <= clock_counter + 1;
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rc <= '0;
        end
        else begin
            if (!mon_axi.ARVALID && (rc.outstanding == 0)) begin
                rc.idle <= rc.idle + 1;
            end

            if (mon_axi.ARVALID && mon_axi.ARREADY) begin
                if (!(mon_axi.RVALID && mon_axi.RREADY && mon_axi.RLAST)) begin
                    rc.outstanding <= rc.outstanding + 1;
                end
            end
            else begin
                if (mon_axi.RVALID && mon_axi.RREADY && mon_axi.RLAST) begin
                    rc.outstanding <= rc.outstanding - 1;
                end
            end


            // --- //
            if (mon_axi.ARVALID && !mon_axi.ARREADY) begin
                rc.ar_stall <= rc.ar_stall + 1;
            end

            if (mon_axi.ARVALID && mon_axi.ARREADY) begin
                rc.ar_handshake <= rc.ar_handshake + 1;
            end


            // --- //
            if ((rc.outstanding != 0) && !mon_axi.RVALID) begin
                rc.rvalid_stall <= rc.rvalid_stall + 1;
            end
            
            if (mon_axi.RVALID && !mon_axi.RREADY) begin
                rc.rready_stall <= rc.rready_stall + 1;
            end

            if (mon_axi.RVALID && mon_axi.RREADY) begin
                rc.r_handshake <= rc.r_handshake + 1;
            end
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wc <= '0;
        end
        else begin
            if (!mon_axi.AWVALID && (wc.outstanding == 0)) begin
                wc.idle <= wc.idle + 1;
            end

            if (mon_axi.AWVALID && mon_axi.AWREADY) begin
                if (!(mon_axi.BVALID && mon_axi.BREADY)) begin
                    wc.outstanding <= wc.outstanding + 1;
                end
            end
            else begin
                if (mon_axi.BVALID && mon_axi.BREADY) begin
                    wc.outstanding <= wc.outstanding - 1;
                end
            end

            if (mon_axi.BVALID && mon_axi.BVALID) begin
                if (!(mon_axi.WVALID && mon_axi.WREADY && mon_axi.WLAST)) begin
                    wc.responding <= wc.responding - 1;
                end
            end
            else begin
                if (mon_axi.WVALID && mon_axi.WREADY && mon_axi.WLAST) begin
                    wc.responding <= wc.responding + 1;
                end
            end


            // --- //
            if (mon_axi.AWVALID && !mon_axi.AWREADY) begin
                wc.aw_stall <= wc.aw_stall + 1;
            end

            if (mon_axi.AWVALID && mon_axi.AWREADY) begin
                wc.aw_handshake <= wc.aw_handshake + 1;
            end


            // --- //
            if ((wc.outstanding != 0) && (wc.outstanding != wc.responding) && !mon_axi.WVALID) begin
                wc.wvalid_stall <= wc.wvalid_stall + 1;
            end

            if (mon_axi.WVALID && !mon_axi.WREADY) begin
                wc.wready_stall <= wc.wready_stall + 1;
            end
            
            if (mon_axi.WVALID && mon_axi.WREADY) begin
                wc.w_handshake <= wc.w_handshake + 1;
            end


            // --- //
            if ((wc.responding != 0) && !mon_axi.BVALID) begin
                wc.bvalid_stall <= wc.bvalid_stall + 1;
            end

            if (mon_axi.BVALID && !mon_axi.BREADY) begin
                wc.bready_stall <= wc.bready_stall + 1;
            end
            
            if (mon_axi.BVALID && mon_axi.BREADY) begin
                wc.b_handshake <= wc.b_handshake + 1;
            end
        end
    end
    
endmodule