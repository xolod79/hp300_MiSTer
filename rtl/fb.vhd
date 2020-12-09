library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity fb is port (
	clk_i		: in std_logic;
	clk_pixel_i	: in std_logic;
	reset_i		: in std_logic;
	ce_pixel_o	: out std_logic;
	hblank_o	: out std_logic;
	vblank_o	: out std_logic;
	hsync_o		: out std_logic;
	vsync_o		: out std_logic;
	r_o		: out std_logic_vector(7 downto 0);
	g_o		: out std_logic_vector(7 downto 0);
	b_o		: out std_logic_vector(7 downto 0);

	db_i		: in std_logic_vector(15 downto 0);
	db_o		: out std_logic_vector(15 downto 0);
	addr_i		: in std_logic_vector(19 downto 0);
	vram_cs_i	: in std_logic;
	rwn_i		: in std_logic;
	rdy_o		: out std_logic;
	udsn_i		: in std_logic;
	ldsn_i		: in std_logic;
	ctl_cs_i	: in std_logic);
end entity fb;

architecture rtl of fb is

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
	rdy_o		: out std_logic;
	udsn_i		: in std_logic;
	ldsn_i		: in std_logic);
end component;

signal video_s		: std_logic;
begin

r_o <= x"ff" when video_s = '1' else x"00";
g_o <= x"ff" when video_s = '1' else x"00";
b_o <= x"ff" when video_s = '1' else x"00";

ce_pixel_o <= '1';

topcat_i: topcat port map(
	clk_i		=> clk_i,
	clk_pixel_i	=> clk_pixel_i,
	reset_i		=> reset_i,
	hblank_o	=> hblank_o,
	vblank_o	=> vblank_o,
	hsync_o		=> hsync_o,
	vsync_o		=> vsync_o,
	video_o		=> video_s,
	db_i		=> db_i,
	db_o		=> db_o,
	addr_i		=> addr_i,
	vram_cs_i	=> vram_cs_i,
	ctl_cs_i	=> ctl_cs_i,
	rwn_i		=> rwn_i,
	rdy_o		=> rdy_o,
	udsn_i		=> udsn_i,
	ldsn_i		=> ldsn_i);
end rtl;
