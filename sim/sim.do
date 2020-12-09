#rm -rf work
#vdel -all -lib work
vlib work
vcom -O5 +acc=p rtl/68K30L/wf68k30L_pkg.vhd \
	rtl/68K30L/wf68k30L_top.vhd \
	rtl/68K30L/wf68k30L_address_registers.vhd \
	rtl/68K30L/wf68k30L_data_registers.vhd \
	rtl/68K30L/wf68k30L_exception_handler.vhd \
	rtl/68K30L/wf68k30L_alu.vhd \
	rtl/68K30L/wf68k30L_control.vhd \
	rtl/68K30L/wf68k30L_opcode_decoder.vhd \
	rtl/68K30L/wf68k30L_bus_interface.vhd \
	rtl/ptm6840.vhd \
	rtl/videoram.vhd \
	rtl/topcat.vhd \
	rtl/fb.vhd \
	rtl/hif.vhd \
	rtl/videorom.vhd \
	rtl/bootrom_d_sim.vhd \
	sim/conversions.vhd \
	sim/gen_utils.vhd \
	sim/mt48lc32m16a2.vhd \
	sim/tb_top.vhd

vcom -O5 +acc=prn rtl/hp300.vhd rtl/sdram.vhd
vsim work.tb_top
#restart -f
quietly set StdArithNoWarnings 1
delete wave *
#force /tb_top/hp300/ps2_key 0 0ns, 11'h65a 4000ms

add wave -radix hex /tb_top/dut/led_s
add wave -radix hex /tb_top/dut/clk_i
#add wave -group cpu -radix hex -r /tb_top/dut/cpu_i/*
add wave -group hp300 /tb_top/dut/bus_state_s
add wave -group hp300 -radix hex /tb_top/dut/cpu_addr_s
add wave -group hp300 -radix hex /tb_top/dut/cpu_data_in_s
add wave -group hp300 -radix hex /tb_top/dut/cpu_data_out_s
add wave -radix hex /tb_top/dut/cpu_rw_n_s
add wave -radix hex /tb_top/dut/cpu_size_s
add wave -radix hex /tb_top/dut/cpu_ds_s
add wave -group hp300 /tb_top/dut/cpu_as_n_s
add wave -group hp300 /tb_top/dut/cpu_dsack_n_s
add wave -group hp300 /tb_top/dut/cpu_berr_n_s
#add wave -group hp300 /tb_top/dut/bootrom_cs_s
add wave -group hp300 /tb_top/dut/sdram_cs_s
#add wave -group hp300 /tb_top/dut/ptm_cs_s
#add wave -group hp300 /tb_top/dut/pmmu_cs_s
#add wave -group hp300 /tb_top/dut/videorom_cs_s
#add wave -group hp300 /tb_top/dut/fb_cs_s
#add wave -group hp300 /tb_top/dut/hif_cs_s
#add wave -radix hex -group hif /tb_top/hp300/human_interface/*
#add wave -group ptm -radix hex -r /tb_top/dut/ptm_i/*
#add wave -group hif -radix hex -r /tb_top/dut/hif_i/*
add wave  -group sdram_cont -radix hex -r /tb_top/dut/sdram_i/*
#add wave  -group sdram -radix hex -r /tb_top/sdram/*
#add wave -group ioctl -radix hex /tb_top/dut/ioctl_write_i
#add wave -group ioctl -radix hex /tb_top/dut/ioctl_read_i
#add wave -group ioctl -radix hex /tb_top/dut/ioctl_wait_o
#add wave -group ioctl -radix hex /tb_top/dut/ioctl_addr_i
#add wave -group ioctl -radix hex /tb_top/dut/ioctl_data_i
#add wave -group ioctl -radix hex /tb_top/dut/ioctl_data_o
#add wave -group ioctl -radix hex /tb_top/dut/ioctl_download_i
#add wave  -group fb -radix hex -r /tb_top/dut/fb_i/*
run 2000ms
#mem save -o test.mem -f mti -data binary -addr hex /tb_top/hp300/fb/vram

