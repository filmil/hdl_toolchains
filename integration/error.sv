module error_tb;
  initial begin
    $error("expected error");
    $finish;
  end
endmodule
