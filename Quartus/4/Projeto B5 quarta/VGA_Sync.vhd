library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
port(
	clk : in std_logic;
	rst : in std_logic;
	H_sync: out std_logic;
	V_sync: out std_logic;
	VGA_CLK: out std_logic;
	ColorBurst :out std_logic
);
end entity;

architecture arch of vga_sync is

	signal vga_clock: std_logic;
	signal vga_clock_count: unsigned(0 downto 0) := (others => '0');
	constant WIDTH: integer := 12;
	
--	constant LINE_SIZE: unsigned(9 downto 0) := to_unsigned(800, 10);
--	constant H_SYNC_SiZE: unsigned(9 downto 0) := to_unsigned(96, 10);
--	constant H_SYNC_BACK: unsigned(9 downto 0) := to_unsigned(144, 10);
--	constant H_SYNC_FRONT: unsigned(9 downto 0) := to_unsigned(16, 10);
--	constant LINE_AMNT: unsigned(9 downto 0) := to_unsigned(525, 10);
--	constant V_SYNC_SiZE: unsigned(9 downto 0) := to_unsigned(2, 10);
--	constant V_SYNC_BACK: unsigned(9 downto 0) := to_unsigned(34, 10);
--	constant V_SYNC_FRONT: unsigned(9 downto 0) := to_unsigned(11, 10);
	
	constant LINE_SIZE: unsigned(WIDTH-1 downto 0) := to_unsigned(1792, WIDTH);
	constant H_SYNC_SiZE: unsigned(WIDTH-1 downto 0) := to_unsigned(143, WIDTH);
	constant H_SYNC_BACK: unsigned(WIDTH-1 downto 0) := to_unsigned(356, WIDTH);
	constant H_SYNC_FRONT: unsigned(WIDTH-1 downto 0) := to_unsigned(70, WIDTH);
	constant LINE_AMNT: unsigned(WIDTH-1 downto 0) := to_unsigned(798, WIDTH);
	constant V_SYNC_SiZE: unsigned(WIDTH-1 downto 0) := to_unsigned(3, WIDTH);
	constant V_SYNC_BACK: unsigned(WIDTH-1 downto 0) := to_unsigned(27, WIDTH);
	constant V_SYNC_FRONT: unsigned(WIDTH-1 downto 0) := to_unsigned(3, WIDTH);
	
	
	signal h_cnt: unsigned(WIDTH-1 downto 0) := (others => '0');
	signal v_cnt: unsigned(WIDTH-1 downto 0) := (others => '0');
	signal cHD, cVD, cDEN, hori_valid, vert_valid: std_logic;
	
	component ClockVGA is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		locked   : out std_logic         --  locked.export
	);
	end component ClockVGA;
begin

--	vga_clock_proc:
--	process (clk, rst) is
--	begin
--		if rst = '0' then
--			vga_clock_count <= (others => '0');
--		elsif rising_edge(clk) then
--			vga_clock_count <= vga_clock_count + 1;
--		end if;
--	end process;
--
--	vga_clock <= vga_clock_count(0);
   VGA_CLK <= vga_clock;

	clk_vga: ClockVGA
	port map(
		refclk   => clk,
		rst      => '0',
		outclk_0 => vga_clock
	);
		
	
	process(vga_clock, rst) is
	begin
		if rst = '0' then
			h_cnt <= (others => '0');
			v_cnt <= (others => '0');
		elsif falling_edge(vga_clock) then
			if h_cnt = LINE_SIZE - 1 then
				h_cnt <= (others => '0');
				if v_cnt=LINE_AMNT-1 then
					v_cnt<= (others => '0');
				else
					v_cnt<=v_cnt+1;
				end if;
			else
				h_cnt <= h_cnt + 1;
			end if;
		end if;
	end process;
	
	
	cHD <= '0' when h_cnt<H_SYNC_SiZE else '1';
	cVD <= '0' when v_cnt<V_SYNC_SiZE else '1';

	hori_valid <= '1' when (h_cnt<(LINE_SIZE-H_SYNC_FRONT-1) and h_cnt>=H_SYNC_BACK) else '0';
	vert_valid <= '1' when (v_cnt<(LINE_AMNT-V_SYNC_FRONT) and v_cnt>=V_SYNC_BACK) else '0';

	cDEN <= hori_valid and vert_valid;

	process(vga_clock) is
	begin
		if falling_edge(vga_clock) then
			H_sync <= not cHD;
			V_Sync <= not cVD;
			ColorBurst <= cDEN;
		end if;
	end process;


end architecture;