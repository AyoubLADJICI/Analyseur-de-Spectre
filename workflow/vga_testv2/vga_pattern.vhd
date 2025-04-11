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
        blue        : out STD_LOGIC_VECTOR(3 downto 0);
        
        -- AXI STREAM 
        tdata    : in STD_LOGIC_VECTOR(31 downto 0); -- 4 bits R + 4 G + 4 B
        tvalid   : in STD_LOGIC;
        tready   : out STD_LOGIC;
        tlast    : in STD_LOGIC
    );
end vga_pattern;

architecture Behavioral of vga_pattern is
begin
    process(pixel_x, pixel_y, video_on, tdata, tvalid)
    begin
        --if video_on = '1' and tvalid = '1' then
            --red   <= tdata(11 downto 8);
            --green <= tdata(7 downto 4);
            --blue  <= tdata(3 downto 0);
        --else
            --red   <= (others => '0');
           -- green <= (others => '0');
           -- blue  <= (others => '0');
        --end if;
        -- Drapeau des Comores avec triangle vert à gauche
        
            if video_on = '1' then
                if tvalid = '1' then
                    -- Couleur via AXI (par exemple : violet avec tdata = x"00000F0F")
                    red   <= tdata(11 downto 8);
                    green <= tdata(7 downto 4);
                    blue  <= tdata(3 downto 0);
                else
                    -- Fond : damier noir et blanc (64x64)
                    if ((to_integer(unsigned(pixel_x)) / 64) mod 2) = ((to_integer(unsigned(pixel_y)) / 64) mod 2) then
                        red   <= "1111";
                        green <= "1111";
                        blue  <= "1111";  -- Blanc
                    else
                        red   <= "0000";
                        green <= "0000";
                        blue  <= "0000";  -- Noir
                    end if;
                end if;
            else
                -- En dehors de la zone visible
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
            end if;

    end process;

    tready <= video_on; -- On est prêt à lire uniquement quand on affiche

end Behavioral;


