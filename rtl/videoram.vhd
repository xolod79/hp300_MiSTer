library ieee;
use ieee.std_logic_1164.all;

entity videoram is
port (
	cpu_clock_i		: in std_logic;
	cpu_data_i		: in std_logic;
	cpu_data_o		: out std_logic;
	cpu_write_addr_i	: in integer range 0 to 1048575;
	cpu_read_addr_i		: in integer range 0 to 1048575;
	cpu_write_i		: in std_logic;
	cpu_read_i		: in std_logic;

	video_clock_i		: in std_logic;
	video_read_addr_i	: in integer range 0 to 1048575;
	video_data_o		: out std_logic
);
end videoram;
architecture rtl of videoram is

type mem is array(0 TO 1048575) of std_logic;
signal ram_block: MEM;
signal video_read_addr_reg : integer range 0 to 1048575;
signal cpu_read_addr_reg : integer range 0 to 1048575;

begin
process (cpu_clock_i)
begin
	if (rising_edge(cpu_clock_i)) then
		if (cpu_write_i = '1') then
			ram_block(cpu_write_addr_i) <= cpu_data_i;
		end if;
	end if;
end process;

process (cpu_clock_i)
begin
	if (rising_edge(cpu_clock_i)) then
		cpu_data_o <= ram_block(cpu_read_addr_i);
	end if;
end process;

process (video_clock_i)
begin
	if (rising_edge(video_clock_i)) then
		video_data_o <= ram_block(video_read_addr_i);
	end if;
end process;

end rtl;