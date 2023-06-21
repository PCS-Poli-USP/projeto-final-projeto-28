library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Toplevel is
port (
	rst	: in	std_logic;
	clks	: in	std_logic_vector(3 downto 0);
	--hex0	: out	std_logic_vector(6 downto 0);
	--hex1	: out	std_logic_vector(6 downto 0);
	--hex2	: out	std_logic_vector(6 downto 0);
	--hex3	: out	std_logic_vector(6 downto 0);
	--hex4	: out	std_logic_vector(6 downto 0);
	--hex5	: out	std_logic_vector(6 downto 0);
	LEDs	: out	std_logic_vector(9 downto 0);
	DIPs	: in	std_logic_vector(9 downto 0);
	--KEYs	: in	std_logic_vector(3 downto 0);
	GPIO	: inout	std_logic_vector(35 downto 0); --0 2 16 18 MAIS SENSIVEL
	VGA_H : out std_logic;
	VGA_V : out std_logic;
	VGA_R : out std_logic_vector(3 downto 0);
	VGA_G : out std_logic_vector(3 downto 0);
	VGA_B : out std_logic_vector(3 downto 0)
);
end entity;

architecture rtl of Toplevel is

	component vga_sync is
	port(
		clk : in std_logic;
		rst : in std_logic;
		H_sync: out std_logic;
		V_sync: out std_logic;
		VGA_CLK: out std_logic;
		ColorBurst :out std_logic
	);
	end component;
	
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
	end component;
	
	component rom_linha is
	port (
      addr  : in std_logic_vector(8 downto 0);
		data  : out std_logic_vector(11 downto 0)
	);
	end component rom_linha;
	
	signal color_en : std_logic;
	
	signal h_s, v_s, vga_clk:std_logic;
	signal up_count: std_logic;
	signal count_px: unsigned(18 downto 0) := (others => '0');
	signal count_px_l: unsigned(8 downto 0) := (others => '0');
	signal rom_out : std_logic_vector(11 downto 0);
begin

	vga_s: vga_sync
	port map(
		clk => clks(2),
		rst => rst,
		VGA_CLK => vga_clk, 
		H_sync => h_s,
		V_sync => v_s,
		ColorBurst => color_en
	);
	VGA_H <= h_s;
	VGA_V <= v_s;
	
	
	borda_h: detector_borda
	port map(
      clk	=> clks(0),
		rst	=> rst,
		borda	=> vga_clk,
		update=> up_count
	);
	
	process(clks(0), rst, up_count, v_s) is
	begin
		if rst = '0' then
			count_px <= (others => '0');
		elsif rising_edge(clks(0)) then
			if v_s = '0' then
				count_px <= (others => '0');
			elsif up_count='1' and color_en = '1' then
				count_px <= count_px +1;
			end if;
		end if;
	end process;
	LEDs <= std_logic_Vector(count_px(18 downto 9));
	
	
	process(clks(0), rst, h_s) is
	begin
		if rst = '0' then
			count_px_l <= (others => '0');
		elsif rising_edge(clks(0)) then
			if h_s = '0' then
				count_px_l <= (others => '0');
			elsif up_count='1' and color_en = '1' then
				count_px_l <= count_px_l + 1;
			end if;
		end if;
	end process;
	
	rl: rom_linha
	port map (
      addr  => std_logic_vector(count_px_l),
		data  => rom_out
	);
	
	
	GPIO(0) <= h_s;
	GPIO(1) <= v_s;
	GPIO(2) <= color_en;
	GPIO(3) <= vga_clk;
	GPIO(35 downto 4) <= (others => '0');
	VGA_R <= rom_out(03 downto 0) when color_en = '1' else (others => '0');
	VGA_G <= rom_out(07 downto 4) when color_en = '1' else (others => '0');
	VGA_B <= rom_out(11 downto 8) when color_en = '1' else (others => '0');
	
end architecture;