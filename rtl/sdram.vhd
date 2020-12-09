library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sdram is port (
	-- sdram interface
	sd_data_io		: inout std_logic_vector(15 downto 0);
	sd_addr_o		: out std_logic_vector(12 downto 0);
	sd_ba_o			: out std_logic_vector(1 downto 0);
	sd_cs_n_o		: out std_logic;
	sd_we_n_o		: out std_logic;
	sd_ras_n_o		: out std_logic;
	sd_cas_n_o		: out std_logic;
	sd_clk_o		: out std_logic;

	-- cpu/chipset interface
	reset_i		: in std_logic;
	clk_i		: in std_logic;
	clk2_i		: in std_logic;
	din_i		: in std_logic_vector(31 downto 0);
	dout_o		: out std_logic_vector(31 downto 0);
	addr_i		: in std_logic_vector(25 downto 0);
	ds_i		: in std_logic_vector(3 downto 0);
	req_i		: in std_logic;
	we_i		: in std_logic;
	busy_o		: out std_logic);
end entity sdram;

architecture rtl of sdram is

type state_type is ( RESET, RESET_PRECHARGE, LOAD_MODE, PRE_IDLE, IDLE, ACTIVE_NOP0, ACTIVE_NOP1, CAS0, CAS1, CAS2, CAS3, WAIT_CPU_ACK );

signal state_s			: state_type;
signal sd_data_io_oe_s		: std_logic;
signal sd_data_io_out_s		: std_logic_vector(15 downto 0);
signal sd_cmd_s			: std_logic_vector(3 downto 0);
signal sd_data_io_in_del_s	: std_logic_vector(15 downto 0);
signal rdy_s			: boolean;
signal busy_s			: boolean;
constant CMD_NOP		: std_logic_vector(3 downto 0) := "0111";
constant CMD_ACTIVE		: std_logic_vector(3 downto 0) := "0011";
constant CMD_READ		: std_logic_vector(3 downto 0) := "0101";
constant CMD_WRITE		: std_logic_vector(3 downto 0) := "0100";
constant CMD_BURST_TERMINATE	: std_logic_vector(3 downto 0) := "0110";
constant CMD_PRECHARGE		: std_logic_vector(3 downto 0) := "0010";
constant CMD_AUTO_REFRESH	: std_logic_vector(3 downto 0) := "0001";
constant CMD_LOAD_MODE		: std_logic_vector(3 downto 0) := "0000";

begin

sd_data_io <= sd_data_io_out_s when sd_data_io_oe_s = '1' else (others => 'Z');
sd_clk_o <= not clk_i;

datdel: process(clk_i)
begin
	if (falling_edge(clk_i)) then
		sd_data_io_in_del_s <= sd_data_io;
	end if;
end process;

sd_we_n_o  <= sd_cmd_s(0);
sd_cas_n_o <= sd_cmd_s(1);
sd_ras_n_o <= sd_cmd_s(2);
sd_cs_n_o  <= sd_cmd_s(3);
busy_o <= '1' when busy_s else '0';

busyff: process(reset_i, clk_i)
begin
	if (reset_i = '1') then
		busy_s <= true;
	elsif (rising_edge(clk_i)) then
		if (rdy_s) then
			busy_s <= false;
		elsif (req_i = '1') then
			busy_s <= true;
		end if;
	end if;
end process;

sdram_proc: process(reset_i, clk_i)

variable resetcnt_v		: integer;
variable idle_count_v		: integer;
variable refcnt_v		: integer;

begin
	if(reset_i = '1') then
		state_s <= RESET;
		sd_cmd_s <= CMD_NOP;
		resetcnt_v := 0;
		sd_data_io_oe_s <= '0';
		sd_ba_o <= "00";
		refcnt_v := 0;
		sd_addr_o <= "1100000000000";
		rdy_s <= false;
	elsif (rising_edge(clk_i)) then
		refcnt_v := refcnt_v + 1;
		case state_s is
			when RESET =>
				sd_addr_o <= "1100000000000";
				if (resetcnt_v < 20000) then
					resetcnt_v := resetcnt_v + 1;
				else
					state_s <= RESET_PRECHARGE;
					resetcnt_v := 0;
				end if;
			when RESET_PRECHARGE =>
				if (resetcnt_v = 0) then
					sd_cmd_s <= CMD_PRECHARGE;
					sd_addr_o <= "0010000000000";
					resetcnt_v := 1;
				elsif (resetcnt_v < 16) then
					sd_cmd_s <= CMD_NOP;
					resetcnt_v := resetcnt_v + 1;
				else
					state_s <= LOAD_MODE;
					resetcnt_v := 0;
				end if;
			when LOAD_MODE =>
				if (resetcnt_v = 0) then
					sd_cmd_s <= CMD_LOAD_MODE;
					sd_addr_o <= "0000000100001";
					resetcnt_v := 1;
				elsif (resetcnt_v < 16) then
					resetcnt_v := resetcnt_v + 1;
					sd_cmd_s <= CMD_NOP;
				else
					state_s <= PRE_IDLE;
					idle_count_v := 200;
					resetcnt_v := 0;
				end if;
			when PRE_IDLE =>
				rdy_s <= false;
				if (idle_count_v > 0) then
					idle_count_v := idle_count_v - 1;
					sd_cmd_s <= CMD_NOP;
				else
					state_s <= IDLE;
				end if;

			when IDLE =>
				rdy_s <= false;
				if (refcnt_v > 200) then
					refcnt_v := 0;
					sd_addr_o <= (others => '0');
					sd_ba_o <= "00";
					sd_data_io_oe_s <= '0';
					sd_cmd_s <= CMD_AUTO_REFRESH;
					idle_count_v := 6;
					state_s <= PRE_IDLE;
				elsif (busy_s) then
					-- RAS phase
					sd_cmd_s <= CMD_ACTIVE;
					sd_addr_o <= addr_i(23 downto 11);
					sd_ba_o <= addr_i(25 downto 24);
					state_s <= ACTIVE_NOP0;
					sd_data_io_oe_s <= we_i;
				end if;

			when ACTIVE_NOP0 =>
				sd_cmd_s <= CMD_NOP;
				sd_data_io_oe_s <= we_i;
				state_s <= ACTIVE_NOP1;

			when ACTIVE_NOP1 =>
				sd_cmd_s <= CMD_NOP;
				state_s <= CAS0;
				sd_data_io_out_s <= din_i(15 downto 0);
				sd_data_io_oe_s <= we_i;

			when CAS0 =>
			-- CAS phase
				sd_data_io_out_s <= din_i(15 downto 0);
				sd_addr_o <= ds_i(1 downto 0) & '1' & addr_i(10 downto 2) & '0';  -- auto precharge
				if (we_i = '1') then
					sd_cmd_s <=  CMD_WRITE;
				else
					sd_cmd_s <= CMD_READ;
					sd_data_io_oe_s <= we_i;
				end if;
				state_s <= CAS1;
			when CAS1  =>
				sd_addr_o <= ds_i(3 downto 2) & '1' & addr_i(10 downto 2) & '0';  -- auto precharge
				sd_data_io_out_s <= din_i(31 downto 16);
				sd_cmd_s <= CMD_NOP;
				state_s <= CAS2;

			when CAS2 =>
				state_s <= CAS3;
				sd_data_io_oe_s <= '0';
			when CAS3 =>
				sd_cmd_s <= CMD_NOP;
				idle_count_v := 0;
				sd_data_io_oe_s <= '0';
				state_s <= WAIT_CPU_ACK;
				dout_o(15 downto 0) <= sd_data_io_in_del_s;

			when WAIT_CPU_ACK =>
				state_s <= PRE_IDLE;
				dout_o(31 downto 16) <= sd_data_io_in_del_s;
				rdy_s <= true;
		end case;
	end if;
end process;
end rtl;
