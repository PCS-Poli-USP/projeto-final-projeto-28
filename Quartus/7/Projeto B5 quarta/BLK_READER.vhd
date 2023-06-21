library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BLK_READER is
	port (
	clk	 : in  std_logic;
	START	 : in  std_logic;
	inc	 : in 	std_logic;
	Rd_blk : out std_logic;
	blk_num: out std_logic_vector(1 downto 0)
 );
end BLK_READER;

architecture rtl of BLK_READER is

	
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


	signal count : unsigned(1 downto 0) := "00";
	
	type estados is (espera_inicio, espera_fim);
	signal estado: estados := espera_inicio;
	
	signal up_cnt: std_logic;
	signal readed: std_logic;
	signal delay1, delay2 : std_logic;
begin

	dec_inc: detector_borda
		generic map (
			subida => false
		)
		port map(
			clk	=> clk,
			rst	=> '1',
			borda	=> inc,
			update=> delay1
		);

	process(clk) is 
	begin
		if rising_edge(clk) then
			up_cnt <= delay1;
			--up_cnt <= delay2;
		end if;
	end process;
		
	process(clk) is
	begin
		if rising_edge(clk) then
			case estado is
				when espera_inicio =>
					if START = '1' then
						estado <= espera_fim;
						Rd_blk <= '1';
					end if;
				when espera_fim =>
					if up_cnt = '1' then
						count <= count + 1;
						Rd_blk <= '1';
					else
						Rd_blk <= '0';
					end if;
					if count = "00" then
						estado <= espera_inicio;
					end if;
			end case;
		end if;
	end process;

	
	blk_num <= std_logic_vector(count-1);
	
end architecture;