library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ptm6840 is port (
	db_i		: in std_logic_vector(7 downto 0);
	db_o		: out std_logic_vector(7 downto 0);
	rs_i		: in std_logic_vector(2 downto 0);
	e_i		: in std_logic;
	clk_i		: in std_logic;
	cs_i		: in std_logic;
	rwn_i		: in std_logic;
	irq_o		: out std_logic;
	reset_i		: in std_logic;

	g1_i		: in std_logic;
	g2_i		: in std_logic;
	g3_i		: in std_logic;

	c1_i		: in std_logic;
	c2_i		: in std_logic;
	c3_i		: in std_logic;

	o1_o		: out std_logic;
	o2_o		: out std_logic;
	o3_o		: out std_logic);
end entity ptm6840;

architecture rtl of ptm6840 is

signal t1_irq_s		: std_logic;
signal t2_irq_s		: std_logic;
signal t3_irq_s		: std_logic;
signal t1_latch_s	: std_logic_vector(15 downto 0);
signal t2_latch_s	: std_logic_vector(15 downto 0);
signal t3_latch_s	: std_logic_vector(15 downto 0);
signal t1_counter_s	: std_logic_vector(15 downto 0);
signal t2_counter_s	: std_logic_vector(15 downto 0);
signal t3_counter_s	: std_logic_vector(15 downto 0);
signal cr1_s		: std_logic_vector(7 downto 0);
signal cr2_s		: std_logic_vector(7 downto 0);
signal cr3_s		: std_logic_vector(7 downto 0);
signal msb_buffer_s	: std_logic_vector(7 downto 0);
signal lsb_buffer_s	: std_logic_vector(7 downto 0);
signal load_t1_s	: std_logic;
signal load_t2_s	: std_logic;
signal load_t3_s	: std_logic;

signal old_c1_s		: std_logic;
signal old_c2_s		: std_logic;
signal old_c3_s		: std_logic;

signal o1_s		: std_logic;
signal o2_s		: std_logic;
signal o3_s		: std_logic;
begin

load_t3_s <= '1' when rs_i = "111" and cs_i = '1' and rwn_i = '0' else '0';
load_t2_s <= '1' when rs_i = "101" and cs_i = '1' and rwn_i = '0' else '0';
load_t1_s <= '1' when rs_i = "011" and cs_i = '1' and rwn_i = '0' else '0';

o1_o <= o1_s;
o2_o <= o2_s;
o3_o <= o3_s;
irq_o <= '0';
counter1: process(reset_i, clk_i)
begin
	if (reset_i = '1') then
		o1_s <= '0';
		t1_counter_s <= (others => '0');
	elsif (rising_edge(clk_i)) then
		if (load_t1_s = '1') then
			t1_counter_s <= x"00" & t1_latch_s(7 downto 0);
		elsif (old_c1_s = '1' and c1_i = '0') then
			t1_counter_s <= t1_counter_s - 1;
			if (t1_counter_s = x"0000") then
				o1_s <= not o1_s;
			end if;
		end if;
		old_c1_s <= c1_i;
	end if;

end process;

counter2: process(reset_i, clk_i)
begin
	if (reset_i = '1') then
		o2_s <= '0';
		t2_counter_s <= (others => '0');
	elsif (rising_edge(clk_i)) then
		if (load_t2_s = '1') then
			t2_counter_s <= x"00" & t2_latch_s(7 downto 0);
		elsif (old_c2_s = '1' and c2_i = '0') then
			t2_counter_s <= t2_counter_s - 1;
			if (t2_counter_s = x"0000") then
				o2_s <= not o2_s;
			end if;
		end if;
		old_c2_s <= c2_i;
	end if;
end process;

counter3: process(reset_i, clk_i)
begin
	if (reset_i = '1') then
		o3_s <= '0';
		t3_counter_s <= (others => '0');
	elsif (rising_edge(clk_i)) then
		if (load_t3_s = '1') then
			t3_counter_s <= x"00" & t3_latch_s(7 downto 0);
		elsif (old_c3_s = '1' and c3_i = '0') then
			t3_counter_s <= t3_counter_s - 1;
			if (t3_counter_s = x"0000") then
				o3_s <= not o3_s;
			end if;

		end if;
		old_c3_s <= c3_i;
	end if;

end process;

write_proc: process(reset_i, clk_i)
begin
	if (reset_i = '1') then
		cr1_s <= x"00";
		cr2_s <= x"00";
		cr3_s <= x"00";
		t1_latch_s <= x"0000";
		t2_latch_s <= x"0000";
		t3_latch_s <= x"0000";
	elsif (rising_edge(clk_i)) then
		if (cs_i = '1' and rwn_i = '0') then
			case rs_i is
				when "000" =>
					if (cr2_s(0) = '1') then
						cr1_s <= db_i;
					else
						cr3_s <= db_i;
					end if;
				when "001" =>
					cr2_s <= db_i;

				when "010" =>
					msb_buffer_s <= db_i;

				when "011" =>
					t1_latch_s(7 downto 0) <= db_i;
					t1_latch_s(15 downto 8) <= msb_buffer_s;

				when "100" =>
					msb_buffer_s <= db_i;

				when "101" =>
					t2_latch_s(7 downto 0) <= db_i;
					t2_latch_s(15 downto 8) <= msb_buffer_s;

				when "110" =>
					msb_buffer_s <= db_i;

				when "111" =>
					t3_latch_s(7 downto 0) <= db_i;
					t3_latch_s(15 downto 8) <= msb_buffer_s;
				when others =>
			end case;
		end if;
	end if;
end process;

read_proc: process(clk_i)
begin
	if (rising_edge(clk_i)) then
		if (cs_i = '1' and rwn_i = '1') then
			case rs_i is
			when "000" =>
				db_o <= x"00";

			when "001" =>
				db_o <= x"00";

			when "010" =>
				db_o <= t1_counter_s(15 downto 8);
				lsb_buffer_s <= t1_counter_s(7 downto 0);

			when "011" =>
				db_o <= lsb_buffer_s;

			when "100" =>
				db_o <= t2_counter_s(15 downto 8);
				lsb_buffer_s <= t2_counter_s(7 downto 0);

			when "101" =>
				db_o <= lsb_buffer_s;
	
			when "110" =>
				db_o <= t3_counter_s(15 downto 8);
				lsb_buffer_s <= t3_counter_s(7 downto 0);

			when "111" =>
				db_o <= lsb_buffer_s;

			when others =>
			end case;
		end if;
     end if;
end process;

end rtl;
