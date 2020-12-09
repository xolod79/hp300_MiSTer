library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity tb_topcat is port (
	ce_pixel_o	: out std_logic;
	hblank_o	: out std_logic;
	vblank_o	: out std_logic;
	hsync_o		: out std_logic;
	vsync_o		: out std_logic;
	r_o		: out std_logic_vector(7 downto 0);
	g_o		: out std_logic_vector(7 downto 0);
	b_o		: out std_logic_vector(7 downto 0));
end entity tb_topcat;

architecture rtl of tb_topcat is

component topcat is port (
	clk_i		: in std_logic;
	clk_pixel_i	: in std_logic;
	reset_i		: in std_logic;
	hblank_o	: out std_logic;
	vblank_o	: out std_logic;
	hsync_o		: out std_logic;
	vsync_o		: out std_logic;
	video_o		: out std_logic;
	db_i		: in std_logic_vector(15 downto 0);
	db_o		: out std_logic_vector(15 downto 0);
	addr_i		: in std_logic_vector(19 downto 0);
	vram_cs_i	: in std_logic;
	ctl_cs_i	: in std_logic;
	rwn_i		: in std_logic;
	udsn_i		: in std_logic;
	ldsn_i		: in std_logic;
	plane_id_i	: in std_logic_vector(7 downto 0));
end component;

signal plane_id0_s	: std_logic_vector(7 downto 0) := x"01";
signal video_s		: std_logic;
signal clk_s		: std_logic := '0';
signal clk_pixel_s	: std_logic := '0';
signal reset_s		: std_logic := '1';
signal addr_s		: std_logic_vector(19 downto 0);
signal db_out_s		: std_logic_vector(15 downto 0);
signal db_in_s		: std_logic_vector(15 downto 0);
signal vram_cs_s	: std_logic;
signal ctl_cs_s		: std_logic;
signal rwn_s		: std_logic;
signal udsn_s		: std_logic;
signal ldsn_s		: std_logic;

procedure topcat_write(signal clk_i		: in std_logic;
			signal data_o		: out std_logic_vector(15 downto 0);
			signal addr_o		: out std_logic_vector(19 downto 0);
			signal ctl_cs_o		: out std_logic;
			signal vram_cs_o	: out std_logic;
			signal rwn_o		: out std_logic;
			signal udsn_o		: out std_logic;
			signal ldsn_o		: out std_logic;
			constant addr_i		: in std_logic_vector(19 downto 0);
			constant data_i		: in std_logic_vector(15 downto 0)) is
begin
	ctl_cs_o <= '0';

	wait until rising_edge(clk_i);
	addr_o <= addr_i;
	data_o <= data_i;
	rwn_o <= '0';
	udsn_o <= '0';
	ldsn_o <= '0';
	wait until rising_edge(clk_i);
	ctl_cs_o <= '1';	
	wait until rising_edge(clk_i);
	ctl_cs_o <= '0';
	wait until rising_edge(clk_i);
	wait until rising_edge(clk_i);
end procedure;
begin

r_o <= x"ff" when video_s = '1' else x"00";
g_o <= x"ff" when video_s = '1' else x"00";
b_o <= x"ff" when video_s = '1' else x"00";

ce_pixel_o <= '1';

topcat_i: topcat port map(
	clk_i		=> clk_s,
	clk_pixel_i	=> clk_pixel_s,
	reset_i		=> reset_s,
	hblank_o	=> hblank_o,
	vblank_o	=> vblank_o,
	hsync_o		=> hsync_o,
	vsync_o		=> vsync_o,
	video_o		=> video_s,
	db_i		=> db_in_s,
	db_o		=> db_out_s,
	addr_i		=> addr_s,
	vram_cs_i	=> vram_cs_s,
	ctl_cs_i	=> ctl_cs_s,
	rwn_i		=> rwn_s,
	udsn_i		=> udsn_s,
	ldsn_i		=> ldsn_s,
	plane_id_i	=> plane_id0_s);
	
clkgen: process
begin
	wait for 10ns;
	clk_s <= '1';
	wait for 10ns;
	clk_s <= '0';
end process;

pixclkgen: process
begin
	wait for 7.8125ns;
	clk_pixel_s <= '1';
	wait for 7.8125ns;
	clk_pixel_s <= '0';
end process;



main: process
begin
	reset_s <= '1';
	wait for 1000 ns;
	reset_s <= '0';
	wait for 100ns;

	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"64080", x"0101"); -- display plane enable
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"64088", x"0101"); -- write enable
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"6408c", x"0101"); -- read enable
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"64090", x"0101"); -- fb write enable
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"640f2", x"0000"); -- src x
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"640f6", x"0300"); -- src y
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"640fa", x"0000"); -- dst x
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"640fe", x"0000"); -- dst y
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"64102", x"0008"); -- width
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"64106", x"0010"); -- height
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"640ee", x"0303"); -- rule
	topcat_write(clk_s, db_in_s, addr_s, ctl_cs_s, vram_cs_s, rwn_s, udsn_s, ldsn_s, x"6409c", x"0001"); -- start wmove
	wait;
end process;


end rtl;
