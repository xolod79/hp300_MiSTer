library ieee;

use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity tb_top is
end entity;

architecture tb of tb_top is
component hp300 is port(
  	clk_i			: in std_logic;
	clk2_i			: in std_logic;
	reset_i	        	: in std_logic;
	clk_pixel_i		: in std_logic;
	ce_pixel_o		: out std_logic;
	hsync_o			: out std_logic;
	vsync_o			: out std_logic;
	vblank_o		: out std_logic;
	hblank_o		: out std_logic;
	r_o			: out std_logic_vector(7 downto 0);
	g_o			: out std_logic_vector(7 downto 0);
	b_o			: out std_logic_vector(7 downto 0);

	sdram_clk_o		: out std_logic;
	sdram_cke_o		: out std_logic;
	sdram_a_o		: out std_logic_vector(12 downto 0);
	sdram_ba_o		: out std_logic_vector(1 downto 0);
	sdram_dq_io		: inout std_logic_vector(15 downto 0);
	sdram_cs_n_o		: out std_logic;
	sdram_cas_n_o		: out std_logic;
	sdram_ras_n_o		: out std_logic;
	sdram_we_n_o		: out std_logic;
	ps2_key_i		: in std_logic_vector(10 downto 0);
	ioctl_addr_i		: in std_logic_vector(26 downto 0);
	ioctl_data_i		: in std_logic_vector(15 downto 0);
	ioctl_data_o		: out std_logic_vector(15 downto 0);
	ioctl_index_i		: in std_logic_vector(15 downto 0);
	ioctl_read_i		: in std_logic;
	ioctl_write_i		: in std_logic;
	ioctl_wait_o		: out std_logic;
	ioctl_download_i	: in std_logic);
end component;

component mt48lc32m16a2 is generic(
	TimingChecksOn  : BOOLEAN);
	port(
        BA0       : IN    std_logic := 'U';
        BA1       : IN    std_logic := 'U';
        DQMH      : IN    std_logic := 'U';
        DQML      : IN    std_logic := 'U';
        DQ0       : INOUT std_logic := 'U';
        DQ1       : INOUT std_logic := 'U';
        DQ2       : INOUT std_logic := 'U';
        DQ3       : INOUT std_logic := 'U';
        DQ4       : INOUT std_logic := 'U';
        DQ5       : INOUT std_logic := 'U';
        DQ6       : INOUT std_logic := 'U';
        DQ7       : INOUT std_logic := 'U';
        DQ8       : INOUT std_logic := 'U';
        DQ9       : INOUT std_logic := 'U';
        DQ10      : INOUT std_logic := 'U';
        DQ11      : INOUT std_logic := 'U';
        DQ12      : INOUT std_logic := 'U';
        DQ13      : INOUT std_logic := 'U';
        DQ14      : INOUT std_logic := 'U';
        DQ15      : INOUT std_logic := 'U';
        CLK       : IN    std_logic := 'U';
        CKE       : IN    std_logic := 'U';
        A0        : IN    std_logic := 'U';
        A1        : IN    std_logic := 'U';
        A2        : IN    std_logic := 'U';
        A3        : IN    std_logic := 'U';
        A4        : IN    std_logic := 'U';
        A5        : IN    std_logic := 'U';
        A6        : IN    std_logic := 'U';
        A7        : IN    std_logic := 'U';
        A8        : IN    std_logic := 'U';
        A9        : IN    std_logic := 'U';
        A10       : IN    std_logic := 'U';
        A11       : IN    std_logic := 'U';
        A12       : IN    std_logic := 'U';
        WENeg     : IN    std_logic := 'U';
        RASNeg    : IN    std_logic := 'U';
        CSNeg     : IN    std_logic := 'U';
        CASNeg    : IN    std_logic := 'U'
  );
end component;
signal clk_s			: std_logic := '0';
signal clk2_s			: std_logic := '0';
signal reset_s			: std_logic := '1';
signal clk_pixel_s		: std_logic := '0';
signal ce_pixel_s		: std_logic := '1';
signal ps2_key_s		: std_logic_vector(10 downto 0) := (others => '0');

signal sdram_ba_s		: std_logic_vector(1 downto 0);
signal sdram_dq_s		: std_logic_vector(15 downto 0);
signal sdram_a_s		: std_logic_vector(12 downto 0);
signal sdram_clk_s		: std_logic;
signal sdram_cke_s		: std_logic;
signal sdram_cas_n_s		: std_logic;
signal sdram_ras_n_s		: std_logic;
signal sdram_we_n_s		: std_logic;
signal sdram_cs_n_s		: std_logic;

signal ioctl_read_s		: std_logic;
signal ioctl_write_s		: std_logic;
signal ioctl_wait_s		: std_logic;
signal ioctl_download_s		: std_logic;
signal ioctl_addr_s		: std_logic_vector(26 downto 0);
signal ioctl_data_out_s		: std_logic_vector(15 downto 0);
signal ioctl_data_in_s		: std_logic_vector(15 downto 0);
signal ioctl_index_s		: std_logic_vector(15 downto 0);
begin

dut: hp300 port map(
  clk_i => clk_s,
  clk2_i => clk2_s,
  reset_i => reset_s,
  clk_pixel_i => clk_pixel_s,
  ps2_key_i => ps2_key_s,
  sdram_clk_o => sdram_clk_s,
  sdram_cke_o => sdram_cke_s,
  sdram_a_o => sdram_a_s,
  sdram_ba_o => sdram_ba_s,
  sdram_dq_io => sdram_dq_s,
  sdram_cs_n_o => sdram_cs_n_s,
  sdram_we_n_o => sdram_We_n_s,
  sdram_cas_n_o => sdram_cas_n_s,
  sdram_ras_n_o => sdram_ras_n_s,
  ioctl_read_i => ioctl_read_s,
  ioctl_write_i => ioctl_write_s,
  ioctl_wait_o => ioctl_wait_s,
  ioctl_addr_i => ioctl_addr_s,
  ioctl_data_i => ioctl_data_in_s,
  ioctl_data_o => ioctl_data_out_s,
  ioctl_index_i => ioctl_index_s,
  ioctl_download_i => ioctl_download_s
  );

sdram: mt48lc32m16a2 generic map (
	TimingChecksOn => true
	)
	port map(
	BA0 => sdram_ba_s(0),
	BA1 => sdram_ba_s(1),
	DQMH => sdram_a_s(12),
	DQML => sdram_a_s(11),
	DQ0 => sdram_dq_s(0),
	DQ1 => sdram_dq_s(1),
	DQ2 => sdram_dq_s(2),
	DQ3 => sdram_dq_s(3),
	DQ4 => sdram_dq_s(4),
	DQ5 => sdram_dq_s(5),
	DQ6 => sdram_dq_s(6),
	DQ7 => sdram_dq_s(7),
	DQ8 => sdram_dq_s(8),
	DQ9 => sdram_dq_s(9),
	DQ10 => sdram_dq_s(10),
	DQ11 => sdram_dq_s(11),
	DQ12 => sdram_dq_s(12),
	DQ13 => sdram_dq_s(13),
	DQ14 => sdram_dq_s(14),
	DQ15 => sdram_dq_s(15),
	CLK => sdram_clk_s,
	CKE => sdram_cke_s,
	A0 => sdram_a_s(0),
	A1 => sdram_a_s(1),
	A2 => sdram_a_s(2),
	A3 => sdram_a_s(3),
	A4 => sdram_a_s(4),
	A5 => sdram_a_s(5),
	A6 => sdram_a_s(6),
	A7 => sdram_a_s(7),
	A8 => sdram_a_s(8),
	A9 => sdram_a_s(9),
	A10 => sdram_a_s(10),
	A11 => sdram_a_s(11),
	A12 => sdram_a_s(12),
	WENeg => sdram_we_n_s,
	RASNeg => sdram_ras_n_s,
	CSNeg => sdram_cs_n_s,
	CASNeg => sdram_cas_n_s);

clkgen: process
begin
	clk2_s <= '0';
	clk_s <= '0';
	wait for 5 ns;
	clk2_s <= '1';
	wait for 5 ns;
	clk2_s <= '0';
	clk_s <= '1';
	wait for 5 ns;
	clk2_s <= '1';
	wait for 5 ns;
end process;

pixclkgen: process
begin
	clk_pixel_s <= '0';
	wait for 7.8125 ns;
	clk_pixel_s <= '1';
	wait for 7.8125 ns;
end process;

download: process
variable delaycnt: integer := 0;
variable bytecnt: integer := 0;
begin
	wait;-- for 4000 us;
	for bytecnt in 0 to 1024 loop
		wait until falling_edge(clk_s);
		ioctl_addr_s <= std_logic_vector(to_unsigned(bytecnt, ioctl_addr_s'length));
		ioctl_data_in_s <= x"55aa";
		ioctl_write_s <= '1';
		ioctl_read_s <='0';
		ioctl_download_s <= '1';
		wait until rising_edge(clk_s);
		wait until falling_edge(clk_s);
		ioctl_write_s <= '0';
		wait until ioctl_wait_s = '0';
	end loop;
	ioctl_download_s <= '0';
	wait;
end process;
main: process
begin
  	reset_s <= '1';
	wait for 500 ns;
	reset_s <= '0';
	wait;
end process;
end tb;
