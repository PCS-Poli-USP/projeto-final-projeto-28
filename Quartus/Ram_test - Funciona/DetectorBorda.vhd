library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity detector_borda is
	generic (
		subida : boolean := true
	);
	port (
		clk	: in std_logic;
		rst	: in std_logic;
		borda	: in std_logic;
		update: out std_logic
	);
end detector_borda;

architecture rlt of detector_borda is
    type estados is (Waiting_Rise, Work, Waiting_Fall);
    signal EA : estados;
	signal amostragem: std_logic;
begin
	process(rst, clk)
	begin
	  if rst = '0' then
			EA <= Waiting_Rise;
	  elsif rising_edge(clk) then
			if (EA = Waiting_Fall and amostragem = '0') then
				EA <= Waiting_Rise;
			elsif (EA = Waiting_Rise and amostragem = '1') then
				EA <= Work;
			elsif (EA = Work) then
				EA <= Waiting_Fall;
			end if;
	  end if;
	end process;

	amostragem <= borda when subida else not borda;
		
	update <= '1' when EA = Work else '0';
		
end architecture;