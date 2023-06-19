library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin_to_dec_and_digits is
    port (
        bin_num   : in std_logic_vector(7 downto 0);
        digit_0   : out std_logic_vector(7 downto 0);
        digit_1   : out std_logic_vector(7 downto 0);
        digit_2   : out std_logic_vector(7 downto 0)
    );
end entity bin_to_dec_and_digits;

architecture Behavioral of bin_to_dec_and_digits is

    signal dec_num : unsigned range 0 to 255;

begin
    dec_num <= to_integer(unsigned(bin_num));

    digit_2 <= std_logic_vector(to_unsigned((dec_num mod 10)+ 48, 8)); -- converte o primeiro dígito em ASCII
    digit_1 <= std_logic_vector(to_unsigned((dec_num/10) mod 10)+ 48, 8); -- converte o segundo dígito em ASCII
    digit_0 <= std_logic_vector(to_unsigned(((dec_num/100) mod 10) + 48, 8)); -- converte o terceiro dígito em ASCII

end architecture Behavioral;
