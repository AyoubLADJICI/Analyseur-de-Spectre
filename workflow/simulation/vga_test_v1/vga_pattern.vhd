library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_pattern is
    Port (
        pixel_x     : in  STD_LOGIC_VECTOR(10 downto 0);
        pixel_y     : in  STD_LOGIC_VECTOR(9 downto 0);
        video_on    : in  STD_LOGIC;
        red         : out STD_LOGIC_VECTOR(3 downto 0);
        green       : out STD_LOGIC_VECTOR(3 downto 0);
        blue        : out STD_LOGIC_VECTOR(3 downto 0)
    );
end vga_pattern;

architecture Behavioral of vga_pattern is
begin
    process(pixel_x, pixel_y, video_on)
        variable x : integer := 0;
        variable y : integer := 0;
    begin
        if video_on = '1' then
            x := to_integer(unsigned(pixel_x));
            y := to_integer(unsigned(pixel_y));

            if ((x / 64) mod 2 = (y / 64) mod 2) then
                red   <= "1111";
                green <= "0000";
                blue  <= "0000";
            else
                red   <= "0000";
                green <= "0000";
                blue  <= "1111";
            end if;
        else
            red   <= (others => '0');
            green <= (others => '0');
            blue  <= (others => '0');
        end if;
    end process;
end Behavioral;

