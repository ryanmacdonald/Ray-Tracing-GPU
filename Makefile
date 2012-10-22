CC=vcs

FLAGS=-sverilog -debug_all



default: trtr.sv
	$(CC) $(FLAGS) trtr.sv

trtr:
	$(CC) $(FLAGS) -top trtr_tb COMMON/*v COMMON/sim_lib/altera_mf.v COMMON/altfp*/*.v RAYTRACER/int/* PRG/* trtr_tb.sv trtr.sv sram.sv frame_buffer_handler.sv vga.sv

prime_calc:
	$(CC) $(FLAGS) -top tb_prime_calc COMMON/*v COMMON/altfp_mult/*.v COMMON/altfp_add/*.v RAYTRACER/int/prime_calc.sv RAYTRACER/int/TBs/tb_prim_calc.sv

tuv_calc: 
	$(CC) $(FLAGS) -top tb_tuv_calc COMMON/*v COMMON/sim_lib/altera_mf.v COMMON/altfp*/*.v COMMON/altfp_comp/altfp_comp.v RAYTRACER/int/tuv_calc.sv RAYTRACER/int/TBs/tb_tuv_calc.sv

t_comp: 
	$(CC) $(FLAGS) -top tb_t_comp COMMON/*v COMMON/altfp_comp/altfp_comp.v RAYTRACER/int/p_calc.sv RAYTRACER/int/t_comp.sv RAYTRACER/int/TBs/tb_t_comp.sv

int_math: 
	$(CC) $(FLAGS) -top tb_int_math COMMON/*v COMMON/sim_lib/altera_mf.v COMMON/altfp*/*.v RAYTRACER/int/*.sv RAYTRACER/int/TBs/tb_int_math.sv

int_wrap: 
	$(CC) $(FLAGS) -top int_wrap COMMON/*v COMMON/sim_lib/altera_mf.v COMMON/altfp*/*.v RAYTRACER/int/*.sv RAYTRACER/int/int_wrap.sv

prg_int: 
	$(CC) $(FLAGS) -top tb_int_prg COMMON/*v COMMON/sim_lib/altera_mf.v COMMON/altfp*/*.v RAYTRACER/int/*.sv PRG/*.sv tb_int_prg.sv

prg:
	$(CC) $(FLAGS) -top tb_prg COMMON/*v COMMON/altfp_convert/*v COMMON/altfp_mult/*v COMMON/altfp_add/*v PRG/*.sv

cam:
	$(CC) $(FLAGS) -top  camera_controller COMMON/*v COMMON/altfp_convert/*v COMMON/altfp_mult/*v COMMON/altfp_add/*v CAMERA/camera_controller.sv

camera_dp:
	$(CC) $(FLAGS) -top tb_cdp COMMON/*v COMMON/altfp_convert/*v COMMON/altfp_mult/*v COMMON/altfp_add/*v CAMERA/*.sv


camera:
	$(CC) $(FLAGS) -top tb_camera COMMON/*v COMMON/altfp_convert/*v COMMON/altfp_mult/*v COMMON/altfp_add/*v CAMERA/*.sv


clean:
	rm -rf simv
	rm -rf simv.daidir
	rm -rf csrc
	rm -rf ucli.key
	rm -rf simv.vdb
	rm -rf DVEfiles
	rm -rf inter.vpd
