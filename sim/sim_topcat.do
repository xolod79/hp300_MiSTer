#rm -rf work
#vdel -all -lib work
vlib work
vcom -O5 +acc=prn rtl/videoram.vhd rtl/topcat.vhd sim/tb_topcat.vhd
vsim work.tb_topcat
#restart -f
quietly set StdArithNoWarnings 1
delete wave *
#force /tb_top/hp300/ps2_key 0 0ns, 11'h65a 4000ms


add wave  -group fb -radix hex -r /*
run 8us
#mem save -o test.mem -f mti -data binary -addr hex /tb_top/hp300/fb/vram

