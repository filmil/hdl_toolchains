module fatal_tb;
  initial $fatal(1, "expected fatal");
endmodule
