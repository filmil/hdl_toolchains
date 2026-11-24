// Counts to LIMIT on a clock. The limit comes from a define, the step from
// an included header, and a plusarg must be present.
`include "step.svh"

module counter_tb;
  logic clk = 0;
  int count = 0;

  always #5 clk = ~clk;

  initial begin
    if (!$test$plusargs("go")) $fatal(1, "plusarg +go missing");
`ifndef CHECKED
    $fatal(1, "define CHECKED missing");
`endif
  end

  always @(posedge clk) begin
    count <= count + `STEP;
    if (count + `STEP >= `LIMIT) begin
      $display("count=%0d", count + `STEP);
      $finish;
    end
  end
endmodule

// Never instantiated; picking counter_tb with top keeps it from running.
module unused_tb;
  initial $fatal(1, "wrong top");
endmodule
