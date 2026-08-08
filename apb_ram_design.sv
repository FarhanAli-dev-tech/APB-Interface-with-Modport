// APB interface with master/slave modports
interface apb_if (input logic pclk, presetn);
  logic [7:0]  paddr;
  logic        pwrite;
  logic        psel;
  logic        penable;
  logic [31:0] pwdata;
  logic [31:0] prdata;
  logic        pready;
  logic        pslverr;

  modport master (
    input  pclk, presetn, prdata, pready, pslverr,
    output paddr, pwrite, psel, penable, pwdata
  );

  modport slave (
    input  pclk, presetn, paddr, pwrite, psel, penable, pwdata,
    output prdata, pready, pslverr
  );
endinterface
// APB slave RAM
module apb_slave_ram #(
  parameter int DEPTH = 256
) (
  apb_if.slave apb
);

  logic [31:0] mem [0:DEPTH-1];

  always_ff @(posedge apb.pclk or negedge apb.presetn) begin
    if (!apb.presetn) begin
      apb.pready  <= 1'b0;
      apb.pslverr <= 1'b0;
      apb.prdata  <= '0;
    end else begin
      apb.pready  <= 1'b0;
      apb.pslverr <= 1'b0;

      if (apb.psel && apb.penable) begin
        apb.pready <= 1'b1;
        if (apb.pwrite)
          mem[apb.paddr] <= apb.pwdata;
        else
          apb.prdata <= mem[apb.paddr];
      end
    end
  end

endmodule