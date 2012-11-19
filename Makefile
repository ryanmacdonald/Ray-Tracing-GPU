CC=vcs

FLAGS=-sverilog -debug_all



default: trtr.sv
	$(CC) $(FLAGS) trtr.sv

trtr:
	$(CC) $(FLAGS) -top trtr_tb COMMON/*v COMMON/altfp*/*.v RAYTRACER/int/* PRG/*v TBs/trtr_tb.sv PERIPHERALS/sram.sv PERIPHERALS/frame_buffer_handler.sv PERIPHERALS/vga.sv trtr.sv 

t32:
	$(CC) $(FLAGS) -top t32_tb COMMON/*v COMMON/altfp*/*.v TBs/t32_tb.sv SDRAM/*v SDRAM/submodules/*v SDRAM/qsys_sdram_mem_model/synthesis/submodules/*v SDRAM/submodules/*v PERIPHERALS/sram.sv PERIPHERALS/frame_buffer_handler.sv PERIPHERALS/vga.sv PERIPHERALS/temporary_scene_retriever.sv PERIPHERALS/xmodem.sv PERIPHERALS/scene_loader.sv t32.sv

raystore:
	$(CC) $(FLAGS) -top raystore_tb COMMON/*v COMMON/altfp*/*.v RAYTRACER/raystore/*v PRG/*v

cache2:
	$(CC) $(FLAGS) -top cache_tb2 COMMON/*v RAYTRACER/caches/*.sv SDRAM/*v SDRAM/submodules/*v SDRAM/qsys_sdram_mem_model/synthesis/submodules/*v TBs/cache_tb2.sv

cache:
	$(CC) $(FLAGS) -top cache_tb COMMON/*v RAYTRACER/caches/cache.sv TBs/cache_tb.sv

fbh:
	$(CC) $(FLAGS) -top fbh_tb COMMON/*v COMMON/altfp*/*v PERIPHERALS/frame_buffer_handler.sv PERIPHERALS/vga.sv PERIPHERALS/sram.sv TBs/fbh_tb.sv

prime_calc:
	$(CC) $(FLAGS) -top tb_prime_calc COMMON/*v COMMON/altfp_mult/*.v COMMON/altfp_add/*.v RAYTRACER/int/prime_calc.sv RAYTRACER/int/TBs/tb_prim_calc.sv

tuv_calc: 
	$(CC) $(FLAGS) -top tb_tuv_calc COMMON/*v  COMMON/altfp*/*.v COMMON/altfp_comp/altfp_comp.v RAYTRACER/int/tuv_calc.sv RAYTRACER/int/TBs/tb_tuv_calc.sv

t_comp: 
	$(CC) $(FLAGS) -top tb_t_comp COMMON/*v COMMON/altfp_comp/altfp_comp.v RAYTRACER/int/p_calc.sv RAYTRACER/int/t_comp.sv RAYTRACER/int/TBs/tb_t_comp.sv

scene_int:
	$(CC) $(FLAGS) -top tb_scene_int COMMON/*v COMMON/altfp_compare/altfp_compare.v COMMON/altfp_add/altfp_add.v COMMON/altfp_div/altfp_div.v RAYTRACER/scene_int/*v

int_math: 
	$(CC) $(FLAGS) -top tb_int_math COMMON/*v COMMON/altfp*/*.v RAYTRACER/int/*.sv RAYTRACER/int/TBs/tb_int_math.sv

int_wrap: 
	$(CC) $(FLAGS) -top int_wrap COMMON/*v  COMMON/altfp*/*.v RAYTRACER/int/*.sv RAYTRACER/int/int_wrap.sv

new_int: 
	$(CC) $(FLAGS) -top tb_int_unit COMMON/*v COMMON/altfp*/*.v COMMON/altb*/*/*v RAYTRACER/int/*.sv

trav: 
	$(CC) $(FLAGS) -top tb_trav_unit COMMON/*v COMMON/altfp*/*.v COMMON/altb*/*/*v RAYTRACER/trav/*.sv RAYTRACER/raystore/*v

prg_int: 
	$(CC) $(FLAGS) -top tb_int_prg COMMON/*v  COMMON/altfp*/*.v RAYTRACER/int/*.sv PRG/*.sv TBs/tb_int_prg.sv

prg:
	$(CC) $(FLAGS) -top tb_prg COMMON/*v COMMON/altfp_convert/*v COMMON/altfp_mult/*v COMMON/altfp_add/*v PRG/*.sv

prg_int_stall:
	$(CC) $(FLAGS) -top tb_prg COMMON/*v COMMON/altbram_fifo/*/*v PERIPHERALS/*.sv COMMON/altfp*/*.v RAYTRACER/int/*.sv PRG/*.sv TBs/*.sv

cam:
	$(CC) $(FLAGS) -top  camera_controller COMMON/*v COMMON/altfp_convert/*v COMMON/altfp_mult/*v COMMON/altfp_add/*v CAMERA/camera_controller.sv

camera_dp:
	$(CC) $(FLAGS) -top tb_cdp COMMON/*v COMMON/altfp_convert/*v COMMON/altfp_mult/*v COMMON/altfp_add/*v CAMERA/*.sv


camera:
	$(CC) $(FLAGS) -top tb_camera COMMON/*v COMMON/altfp_convert/*v COMMON/altfp_mult/*v COMMON/altfp_add/*v CAMERA/*.sv

sdram:
	$(CC) $(FLAGS) -top top COMMON/*v SDRAM/*v SDRAM/submodules/*v SDRAM/qsys_sdram_mem_model/synthesis/submodules/*v

list: 
	$(CC) $(FLAGS) -top tb_list_unit COMMON/*v COMMON/altfp*/*.v COMMON/bram/*.v  RAYTRACER/list/*.sv

lshape:
	$(CC) $(FLAGS) -top lshape_tb COMMON/*v TBs/lshape_tb.sv

ryan:
	$(CC) $(FLAGS) -top tb_ryan_demo COMMON/*v COMMON/altfp*/*.v PS2/* COMMON/altbram_fifo/altbramfifo_w211_d16/*v RAYTRACER/scene_int/* PRG/*v PERIPHERALS/sram.sv PERIPHERALS/frame_buffer_handler.sv PERIPHERALS/vga.sv CAMERA/*v TBs/tb_ryan_demo.sv ~/18-545/ryan_demo.sv 




clean:
	rm -rf simv
	rm -rf simv.daidir
	rm -rf csrc
	rm -rf ucli.key
	rm -rf simv.vdb
	rm -rf DVEfiles
	rm -rf inter.vpd
