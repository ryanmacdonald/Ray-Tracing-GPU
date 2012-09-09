CC=vcs

FLAGS=-sverilog -debug_all

default: trtr.sv
	$(CC) $(FLAGS) trtr.sv

clean:
	rm -rf simv
	rm -rf simv.daidir
	rm -rf csrc
	rm -rf ucli.key
	rm -rf simv.vdb
	rm -rf DVEfiles
	rm -rf inter.vpd
