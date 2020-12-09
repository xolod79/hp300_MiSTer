library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity topcat is generic (
	plane_id	: natural := 8);
	port (
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
end entity topcat;

architecture rtl of topcat is

component videoram is
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
end component;

signal video_s			: std_logic;
signal video_l			: std_logic;
signal video_h			: std_logic;
signal hsync_s			: std_logic;
signal vblank_s			: std_logic;
signal hblank_s			: std_logic;
signal hc_s			: unsigned(10 downto 0);
signal vc_s			: unsigned(10 downto 0);
signal ramidx			: unsigned(19 downto 0);

signal vram_write_s		: std_logic;
signal vram_read_s		: std_logic;
signal vram_write_addr_s	: integer range 0 to 1048575;
signal vram_read_addr_s		: integer range 0 to 1048575;
signal vram_data_in_s		: std_logic;
signal vram_data_out_s		: std_logic;
signal vram_video_s		: std_logic;
signal vram_db_s		: std_logic;
signal ctl_db_s			: std_logic_vector(15 downto 0);

signal wm_src_x			: integer range 0 to 1023;
signal wm_src_y			: integer range 0 to 1023;
signal wm_dst_x			: integer range 0 to 1023;
signal wm_dst_y			: integer range 0 to 1023;
signal wm_height		: integer range 0 to 1023;
signal wm_width			: integer range 0 to 1023;
signal wm_mrr			: std_logic_vector(3 downto 0);
signal wm_read_addr_s		: integer range 0 to 1048575;
signal wm_req_s			: boolean;
signal wm_active_s		: boolean;
signal wm_done_s		: boolean;
signal wm_direction		: std_logic;

signal wm_data_s		: std_logic;
signal wm_write_addr_s		: integer range 0 to 1048575;

signal wm_start_x		: integer range 0 to 1023;
signal wm_current_x		: integer range 0 to 1023;
signal wm_current_y		: integer range 0 to 1023;
signal wm_inc_x			: integer range -1 to 1;
signal wm_inc_y			: integer range -1 to 1;
signal wm_end_x			: integer range 0 to 1023;
signal wm_end_y			: integer range 0 to 1023;

signal wm_write_s		: std_logic;
signal wm_read_s		: std_logic;

signal cursor_pos_x_s		: integer range 0 to 1023;
signal cursor_pos_y_s		: integer range 0 to 1023;
signal cursor_width_s		: integer range 0 to 1023;
signal cursor_enable_s		: boolean;
signal cursor_blinkcnt_s	: unsigned(4 downto 0);


signal vram_video_read_addr_s	: integer range 0 to 1048575;
signal write_enable	   	: boolean;
signal read_enable		: boolean;
signal display_enable		: boolean;
signal fb_write_enable		: boolean;


type wm_state is (IDLE, ADDR, READ, WRITE0, WRITE, DONE );
signal wm_state_s		: wm_state;
signal wm_data_latch_s		: std_logic;

constant TOPCAT_REG_VBLANK		: std_logic_vector(11 downto 0) := x"040";
constant TOPCAT_REG_WMOVE_ACTIVE	: std_logic_vector(11 downto 0) := x"044";
constant TOPCAT_REG_VRTRC_INTRQ		: std_logic_vector(11 downto 0) := x"048";
constant TOPCAT_REG_WMOVE_INTRQ		: std_logic_vector(11 downto 0) := x"04c";
constant TOPCAT_REG_DISPLAY_ENABLE	: std_logic_vector(11 downto 0) := x"080";
constant TOPCAT_REG_WRITE_ENABLE	: std_logic_vector(11 downto 0) := x"088";
constant TOPCAT_REG_READ_ENABLE		: std_logic_vector(11 downto 0) := x"08c";
constant TOPCAT_REG_FB_WRITE_ENABLE	: std_logic_vector(11 downto 0) := x"090";
constant TOPCAT_REG_WMOVE_IE		: std_logic_vector(11 downto 0) := x"094";
constant TOPCAT_REG_VBLANK_IE		: std_logic_vector(11 downto 0) := x"098";
constant TOPCAT_REG_START_WMOVE		: std_logic_vector(11 downto 0) := x"09c";
constant TOPCAT_REG_BLINK_PLANE_EN	: std_logic_vector(11 downto 0) := x"0a0";
constant TOPCAT_REG_ALT_FRAME_EN	: std_logic_vector(11 downto 0) := x"0a8";
constant TOPCAT_REG_CURSOR_ENABLE	: std_logic_vector(11 downto 0) := x"0ac";
constant TOPCAT_REG_PRR			: std_logic_vector(11 downto 0) := x"0ea";
constant TOPCAT_REG_MRR			: std_logic_vector(11 downto 0) := x"0ee";
constant TOPCAT_REG_SRC_X		: std_logic_vector(11 downto 0) := x"0f2";
constant TOPCAT_REG_SRC_Y		: std_logic_vector(11 downto 0) := x"0f6";
constant TOPCAT_REG_DST_X		: std_logic_vector(11 downto 0) := x"0fa";
constant TOPCAT_REG_DST_Y		: std_logic_vector(11 downto 0) := x"0fe";
constant TOPCAT_REG_WM_WIDTH		: std_logic_vector(11 downto 0) := x"102";
constant TOPCAT_REG_WM_HEIGHT		: std_logic_vector(11 downto 0) := x"106";
constant TOPCAT_REG_CURSOR_X_POS	: std_logic_vector(11 downto 0) := x"10a";
constant TOPCAT_REG_CURSOR_Y_POS	: std_logic_vector(11 downto 0) := x"10e";
constant TOPCAT_REG_CURSOR_WIDTH	: std_logic_vector(11 downto 0) := x"112";

constant TOPCAT_REG_H_VISIBLE		: std_logic_vector(11 downto 0) := x"142";
constant TOPCAT_REG_H_BACK_PORCH	: std_logic_vector(11 downto 0) := x"146";
constant TOPCAT_REG_H_SYNC		: std_logic_vector(11 downto 0) := x"14a";
constant TOPCAT_REG_H_FRONT_PORCH	: std_logic_vector(11 downto 0) := x"14e";

constant TOPCAT_REG_V_VISIBLE		: std_logic_vector(11 downto 0) := x"152";
constant TOPCAT_REG_V_BACK_PORCH	: std_logic_vector(11 downto 0) := x"156";
constant TOPCAT_REG_V_SYNC		: std_logic_vector(11 downto 0) := x"15a";
constant TOPCAT_REG_V_FRONT_PORCH	: std_logic_vector(11 downto 0) := x"15e";

constant TOPCAT_RULE_CLEAR			: std_logic_vector(3 downto 0) := x"0";
constant TOPCAT_RULE_SRC_AND_DST		: std_logic_vector(3 downto 0) := x"1";
constant TOPCAT_RULE_SRC_AND_NOT_DST		: std_logic_vector(3 downto 0) := x"2";
constant TOPCAT_RULE_SRC			: std_logic_vector(3 downto 0) := x"3";
constant TOPCAT_RULE_NOT_SRC_AND_DST		: std_logic_vector(3 downto 0) := x"4";
constant TOPCAT_RULE_NOP			: std_logic_vector(3 downto 0) := x"5";
constant TOPCAT_RULE_SRC_XOR_DST		: std_logic_vector(3 downto 0) := x"6";
constant TOPCAT_RULE_SRC_OR_DST			: std_logic_vector(3 downto 0) := x"7";
constant TOPCAT_RULE_NOT_SRC_AND_NOT_DST	: std_logic_vector(3 downto 0) := x"8";
constant TOPCAT_RULE_NOT_SRC_XOR_DST		: std_logic_vector(3 downto 0) := x"9";
constant TOPCAT_RULE_NOT_DST			: std_logic_vector(3 downto 0) := x"a";
constant TOPCAT_RULE_SRC_OR_NOT_DST		: std_logic_vector(3 downto 0) := x"b";
constant TOPCAT_RULE_NOT_SRC			: std_logic_vector(3 downto 0) := x"c";
constant TOPCAT_RULE_NOT_SRC_OR_DST		: std_logic_vector(3 downto 0) := x"d";
constant TOPCAT_RULE_NOT_SRC_OR_NOT_DST		: std_logic_vector(3 downto 0) := x"e";
constant TOPCAT_RULE_SET			: std_logic_vector(3 downto 0) := x"f";

function prr(
	src	: std_logic;
	dst	: std_logic;
	rule	: std_logic_vector(3 downto 0))
	return std_logic is
begin
	case rule is
		when TOPCAT_RULE_CLEAR => return '0';
		when TOPCAT_RULE_SRC_AND_DST => return src and dst;
		when TOPCAT_RULE_SRC_AND_NOT_DST => return src and not dst;
		when TOPCAT_RULE_SRC => return src;
		when TOPCAT_RULE_NOT_SRC_AND_DST => return not src and dst;
		when TOPCAT_RULE_NOP => return dst;
		when TOPCAT_RULE_SRC_XOR_DST => return src xor dst;
		when TOPCAT_RULE_SRC_OR_DST => return src or dst;
		when TOPCAT_RULE_NOT_SRC_AND_NOT_DST => return not src and not dst;
		when TOPCAT_RULE_NOT_SRC_XOR_DST => return not src xor dst;
		when TOPCAT_RULE_NOT_DST => return not dst;
		when TOPCAT_RULE_SRC_OR_NOT_DST => return src or not dst;
		when TOPCAT_RULE_NOT_SRC => return not src;
		when TOPCAT_RULE_NOT_SRC_OR_DST => return not src or dst;
		when TOPCAT_RULE_NOT_SRC_OR_NOT_DST => return not src or not dst;
		when TOPCAT_RULE_SET => return '1';
		when others => return '0';
	end case;
end prr;
begin

vram: videoram port map(
	video_clock_i		=> clk_pixel_i,
	cpu_clock_i		=> clk_i,
	cpu_write_i		=> vram_write_s,
	cpu_read_i		=> vram_read_s,
	cpu_data_i		=> vram_data_in_s,
	cpu_data_o		=> vram_data_out_s,
	cpu_read_addr_i		=> vram_read_addr_s,
	cpu_write_addr_i	=> vram_write_addr_s,
	video_read_addr_i	=> vram_video_read_addr_s,
	video_data_o		=> vram_video_s);

vblank_o <= vblank_s;
hblank_o <= hblank_s;
hsync_o <= hsync_s;

ramidx <= vc_s(9 downto 0) & hc_s(9 downto 0);
vram_video_read_addr_s <= to_integer(ramidx);

video_o <= '0' when (hblank_s = '1' or vblank_s = '1' or not display_enable) else
		not vram_video_s when cursor_blinkcnt_s(4) = '1' and cursor_enable_s and hc_s >= cursor_pos_x_s and hc_S <= cursor_pos_x_s + cursor_width_s and vc_s >= cursor_pos_y_s and vc_s < cursor_pos_y_s + 2 else
		vram_video_s;

vram_write_addr_s <= to_integer(unsigned(addr_i)) when not wm_active_s else
		wm_write_addr_s;

vram_read_addr_s <=  to_integer(unsigned(addr_i)) when not wm_active_s else
		wm_read_addr_s;

vram_write_s <= '1' when wm_write_s = '1' and wm_active_s else
		'1' when vram_cs_i = '1' and rwn_i = '0' else '0';

vram_data_in_s <= wm_data_s when wm_active_s else
		db_i(8);

vram_read_s <= wm_read_s when wm_active_s else
		'1' when vram_cs_i = '1' and rwn_i = '1' else '0';

db_o <= ctl_db_s when ctl_cs_i = '1' else
	"0000000" & vram_data_in_s &
	"0000000" & vram_data_in_s when vram_cs_i = '1' else
	x"0000";
	


wmff: process(reset_i, clk_i)
begin
	if (reset_i = '1') then
		wm_active_s <= false;
		rdy_o <= '1';
	elsif (rising_edge(clk_i)) then
		if (wm_req_s and vram_cs_i = '0') then
			wm_active_s <= true;
			rdy_o <= '0';
		elsif (wm_done_s) then
			wm_active_s <= false;
			rdy_o <= '1';
		end if;
	end if;
end process;

wmove: process(reset_i, clk_i)
begin
	if (reset_i = '1') then
		wm_done_s <= false;
		wm_state_s <= IDLE;
		wm_write_s <= '1';
	elsif (rising_edge(clk_i)) then

		case wm_state_s is 
			when IDLE =>
				wm_done_s <= false;
				wm_write_s <= '0';
				if (wm_req_s) then
					if (wm_dst_y > wm_src_y) then
						wm_current_y <= wm_height-1;
						wm_end_y <= 0;
						wm_inc_y <= -1;
					else
						wm_current_y <= 0;
						wm_end_y <= wm_height - 1;
						wm_inc_y <= 1;
					end if;

					if (wm_dst_x > wm_src_x) then
						wm_start_x <= wm_width - 1;
						wm_current_x <= wm_width - 1;
						wm_end_x <= 0;
						wm_inc_x <= -1;
					else
						wm_start_x <= 0;
						wm_current_x <= 0;
						wm_end_x <= wm_width - 1;
						wm_inc_x <= 1;
					end if;
					wm_state_s <= ADDR;
				end if;

			when ADDR =>
				wm_read_addr_s <= (wm_current_y + wm_src_y) * 1024 + wm_src_x + wm_current_x;
				wm_write_addr_s <=  (wm_current_y + wm_dst_y) * 1024 + wm_dst_x + wm_current_x;
				wm_state_s <= READ;
				wm_write_s <= '0';
				wm_read_s <= '1';

			when READ =>
				wm_read_addr_s <= wm_write_addr_s;
				wm_state_s <= WRITE0;

			when WRITE0 =>
				wm_data_latch_s <= vram_data_out_s;
				wm_state_s <= WRITE;

			when WRITE =>
				wm_data_s <= prr(wm_data_latch_s, vram_data_out_s, wm_mrr);
				wm_write_s <= '1';
				wm_read_s <= '0';

				if (wm_current_x /= wm_end_x) then
					wm_current_x <= wm_current_x + wm_inc_x;
					wm_state_s <= ADDR;
				else
					wm_current_x <= wm_start_x;
					if (wm_current_y /= wm_end_y) then
						wm_current_y <= wm_current_y + wm_inc_y;
						wm_state_s <= ADDR;
					else
						wm_state_s <= DONE;
					end if;
				end if;
			when DONE =>
				wm_write_s <= '0';
				wm_read_s <= '0';
				wm_done_s <= true;
				wm_state_s <= IDLE;
		end case;
	end if;
end process;

writereg: process(reset_i, clk_i)
begin
	if (reset_i = '1') then
		wm_src_x <= 0;
		wm_src_y <= 0;
		wm_dst_x <= 0;
		wm_dst_y <= 0;
		wm_width <= 0;
		wm_height <= 0;
		wm_req_s <= false;
		write_enable <= false;
		read_enable <= false;
		display_enable <= false;
	elsif (rising_edge(clk_i)) then
		if (wm_active_s) then
			wm_req_s <= false;
		end if;

		if (ctl_cs_i = '1' and rwn_i = '0') then
			if (write_enable) then
				case addr_i(11 downto 0) is
					when TOPCAT_REG_DISPLAY_ENABLE =>
						display_enable <= db_i(plane_id) = '1';

					when TOPCAT_REG_FB_WRITE_ENABLE =>
						fb_write_enable <= db_i(plane_id) = '1';

					when TOPCAT_REG_SRC_X =>
						wm_src_x <= to_integer(unsigned(db_i(9 downto 0)));

					when TOPCAT_REG_SRC_Y =>
						wm_src_y <= to_integer(unsigned(db_i(9 downto 0)));

					when TOPCAT_REG_DST_X =>
						wm_dst_x <= to_integer(unsigned(db_i(9 downto 0)));

					when TOPCAT_REG_DST_Y =>
						wm_dst_Y <= to_integer(unsigned(db_i(9 downto 0)));

					when TOPCAT_REG_WM_WIDTH =>
						wm_width <= to_integer(unsigned(db_i(9 downto 0)));

					when TOPCAT_REG_WM_HEIGHT =>
						wm_height <= to_integer(unsigned(db_i(9 downto 0)));

					when TOPCAT_REG_START_WMOVE =>
						if (not wm_active_s) then
							wm_req_s <= true;
						end if;

					when TOPCAT_REG_MRR =>
						wm_mrr <= db_i(3 downto 0);

					when TOPCAT_REG_CURSOR_X_POS =>
						cursor_pos_x_s <= to_integer(unsigned(db_i(9 downto 0)));

					when TOPCAT_REG_CURSOR_Y_POS =>
						cursor_pos_y_s <= to_integer(unsigned(db_i(9 downto 0)));

					when TOPCAT_REG_CURSOR_WIDTH =>
						cursor_width_s <= to_integer(unsigned(db_i(9 downto 0)));

					when TOPCAT_REG_CURSOR_ENABLE =>
						cursor_enable_s <= db_i(plane_id) = '1';
					when others =>
				end case;
			end if;

			case addr_i(11 downto 0) is
				when TOPCAT_REG_WRITE_ENABLE =>
					write_enable <= db_i(plane_id) = '1';

				when TOPCAT_REG_READ_ENABLE =>
					read_enable <= db_i(plane_id) = '1';
				when others =>
			end case;
		end if;
	end if;
end process;


readreg: process(clk_i)
begin
	if (rising_edge(clk_i)) then
		if (ctl_cs_i = '1' and rwn_i = '1' and read_enable) then
			case addr_i(11 downto 0) is
		  		when TOPCAT_REG_START_WMOVE =>
					if (wm_active_s) then
						ctl_db_s <= (plane_id => '1', plane_id-8 => '1', others =>'0');
					else
						ctl_db_s <= (others => '0');
					end if;
				when others =>
					ctl_db_s <= (others => '0');
			end case;
		end if;
	end if;
end process;

vcnt: process(reset_i, hsync_s)
begin
	if (reset_i = '1') then
		vc_s <= (others => '0');
	elsif (rising_edge(hsync_s)) then
		if (vc_s  < 795) then
			vc_s <= vc_s + 1;
		else
			cursor_blinkcnt_s <= cursor_blinkcnt_s + 1;
			vc_s <= (others => '0');
		end if;

		if (vc_s > 790 and vc_s < 793) then
			vsync_o <= '1';
		else
			vsync_o <= '0';
		end if;

		if (vc_s > 767) then
			vblank_s <= '1';
		else
			vblank_s <= '0';
		end if;
	end if;
end process;

hcnt: process(reset_i, clk_pixel_i)
begin
	if (reset_i = '1') then
		hc_s <= (others => '0');
	elsif (rising_edge(clk_pixel_i)) then
		if (hc_s < 1340) then
			hc_s <= hc_s + 1;
		else
			hc_s <= (others => '0');
		end if;

		if (hc_s > 1064 and hc_s < 1192) then
			hsync_s <= '1';
		else
			hsync_s <= '0';
		end if;

		if (hc_s > 1023) then
			hblank_s <= '1';
		else
			hblank_s <= '0';
		end if;

	end if;
end process;
end rtl;
