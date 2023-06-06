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
	component detector_borda is
	generic (
		subida : boolean := true
	);
	port (
      clk	: in std_logic;
		rst	: in std_logic;
		borda	: in std_logic;
		update: out std_logic
	);
	end component detector_borda;



	signal vga_clock: std_logic;
	signal vga_clock_count: unsigned(0 downto 0) := (others => '0');
	
	signal h_sync_count: unsigned(9 downto 0) := (others => '0');
	signal h_sync_rst: std_logic;
	constant LINE_SIZE: unsigned(9 downto 0) := to_unsigned(800, 10);
	constant H_SYNC_SiZE: unsigned(9 downto 0) := to_unsigned(96, 10);
	constant H_SYNC_BACK: unsigned(9 downto 0) := to_unsigned(48, 10);
	constant H_SYNC_FRONT: unsigned(9 downto 0) := to_unsigned(16, 10);
	CONSTANT H_VA: unsigned(9 downto 0) := to_unsigned(640, 10);
	
	signal v_sync_update: std_logic;
	signal v_sync_rst: std_logic;
	signal v_sync_count: unsigned(9 downto 0) := (others => '0');
	constant LINE_AMOUNT: unsigned(9 downto 0) := to_unsigned(525, 10);
	constant V_SYNC_SiZE: unsigned(9 downto 0) := to_unsigned(2, 10);
	constant V_SYNC_BACK: unsigned(9 downto 0) := to_unsigned(33, 10);
	constant V_SYNC_FRONT: unsigned(9 downto 0) := to_unsigned(10, 10);
	CONSTANT V_VA: unsigned(9 downto 0) := to_unsigned(480, 10);

begin

	vga_clock_proc:
	process (clk, rst) is
	begin
		if rst = '0' then
			vga_clock_count <= (others => '0');
		elsif rising_edge(clk) then
			vga_clock_count <= vga_clock_count + 1;
		end if;
	end process;

	vga_clock <= vga_clock_count(0);
	VGA_CLK <= vga_clock;


	h_sync_proc:
	process (vga_clock, rst, h_sync_rst) is
	begin
		if rst = '0' then
			h_sync_count <= (others => '0');
		elsif rising_edge(vga_clock) then
			if h_sync_rst = '0' then
				h_sync_count <= (others => '0');
			else
				h_sync_count <= h_sync_count + 1;
			end if;
		end if;
	end process;

	h_sync_rst <= '1' when h_sync_count <= LINE_SIZE else '0';
	H_sync <= '0' when h_sync_count < (LINE_SIZE-H_SYNC_BACK) and h_sync_count >= (LINE_SIZE-H_SYNC_BACK-H_SYNC_SiZE) else '1';

	fim_linha: detector_borda
	port map(
		clk	=> vga_clock,
		rst	=> rst,
		borda	=> h_sync_rst,
		update=> v_sync_update
	);

	v_sync_proc:
	process (vga_clock, rst, v_sync_rst, v_sync_update) is
	begin
		if rst = '0' then
			v_sync_count <= (others => '0');
		elsif rising_edge(vga_clock) and v_sync_update = '1' then
			if v_sync_rst = '0' then
				v_sync_count <= (others => '0');
			else
				v_sync_count <= v_sync_count + 1;
			end if;
		end if;
	end process;

	v_sync_rst <= '1' when v_sync_count <= LINE_AMOUNT else '0';
	V_sync <= '0' when v_sync_count < (LINE_AMOUNT-V_SYNC_BACK) and v_sync_count >= (LINE_AMOUNT-V_SYNC_BACK-V_SYNC_SiZE) else '1';


	ColorBurst <= '1' when v_sync_count < V_VA and h_sync_count < H_VA else '0';


end architecture;