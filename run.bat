
del tb_candidate_test.out
del test.vcd

C:\iverilog\bin\iverilog.exe -o tb_candidate_test.out tb.v candidate_test.v
C:\iverilog\bin\vvp.exe tb_candidate_test.out
