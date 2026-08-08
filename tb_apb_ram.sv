// APB transaction and driver (virtual interface based)
class apb_txn;
  rand bit [7:0]  addr;
  rand bit [31:0] wdata;
  rand bit        write;
       bit [31:0] rdata;
endclass

class apb_driver;
  virtual apb_if.master vif;

  function new(virtual apb_if.master vif);
    this.vif = vif;
  endfunction

  task reset();
    vif.psel    = 0;
    vif.penable = 0;
    vif.pwrite  = 0;
    vif.paddr   = 0;
    vif.pwdata  = 0;
    @(posedge vif.presetn);
  endtask

  task write(bit [7:0] addr, bit [31:0] data);
    @(posedge vif.pclk);
    vif.psel    = 1;
    vif.pwrite  = 1;
    vif.paddr   = addr;
    vif.pwdata  = data;
    @(posedge vif.pclk);
    vif.penable = 1;
    @(posedge vif.pclk);
    while (!vif.pready) @(posedge vif.pclk);
    vif.psel    = 0;
    vif.penable = 0;
  endtask

  task read(bit [7:0] addr, output bit [31:0] data);
    @(posedge vif.pclk);
    vif.psel    = 1;
    vif.pwrite  = 0;
    vif.paddr   = addr;
    @(posedge vif.pclk);
    vif.penable = 1;
    @(posedge vif.pclk);
    while (!vif.pready) @(posedge vif.pclk);
    data = vif.prdata;
    vif.psel    = 0;
    vif.penable = 0;
  endtask
endclass

// Top level testbench
  logic pclk = 0;
  logic presetn;

  always #5 pclk = ~pclk;

  apb_if bus (.pclk(pclk), .presetn(presetn));

  apb_slave_ram #(.DEPTH(256)) dut (.apb(bus.slave));

  apb_driver drv;

  initial begin
    bit [31:0] rd_data;
    int        errors;

    drv     = new(bus.master);
    errors  = 0;
    presetn = 0;

    #12 presetn = 1;
    drv.reset();

    for (int i = 0; i < 10; i++) begin
      bit [7:0]  addr;
      bit [31:0] wdata;

      addr  = i;
      wdata = $urandom;

      drv.write(addr, wdata);
      drv.read(addr, rd_data);

      if (rd_data !== wdata) begin
        errors++;
        $display("MISMATCH addr=%0d exp=%0h got=%0h", addr, wdata, rd_data);
      end else begin
        $display("PASS addr=%0d data=%0h", addr, rd_data);
      end
    end

    if (errors == 0) $display("ALL TESTS PASSED");
    else              $display("%0d TESTS FAILED", errors);

    $finish;
  end
  initial begin
      $dumpfile("dump.vcd"); 
      $dumpvars;
end
endmodule