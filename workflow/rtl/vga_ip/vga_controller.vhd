voici le code adapte au vga:library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_controller is
    Port (
        clk         : in  STD_LOGIC;  -- 65 MHz pixel clock
        reset       : in  STD_LOGIC;
        hsync       : out STD_LOGIC;
        vsync       : out STD_LOGIC;
        video_on    : out STD_LOGIC;
        pixel_x     : out STD_LOGIC_VECTOR(10 downto 0);  
        pixel_y     : out STD_LOGIC_VECTOR(9 downto 0)   
    );
end vga_controller;

architecture Behavioral of vga_controller is
    --Synchronisation horizontale
    constant H_DISPLAY : integer := 1024;
    constant H_FRONT_PORCH : integer := 24;
    constant H_SYNC_PULSE : integer := 136;
    constant H_BACK_PORCH : integer := 160;
    constant H_TOTAL : integer := H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;
    
    --Synchronisation verticale
    constant V_DISPLAY : integer := 768;
    constant V_FRONT_PORCH : integer := 3;
    constant V_SYNC_PULSE : integer := 6;
    constant V_BACK_PORCH : integer := 29;
    constant V_TOTAL : integer := V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

    signal h_count : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count : integer range 0 to V_TOTAL - 1 := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                h_count <= 0;
                v_count <= 0;
            else
                if h_count = H_TOTAL - 1 then
                    h_count <= 0;
                    if v_count = V_TOTAL - 1 then
                        v_count <= 0;
                    else
                        v_count <= v_count + 1;
                    end if;
                else
                    h_count <= h_count + 1;
                end if;
            end if;
        end if;
    end process;

    --On abaisse le signal de synchronisation horizontale à 0 lorsque le compteur horizontale
    --est entre H_DISPLAY + H_FRONT_PORCH et H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE
    hsync <= '0' when (h_count >= H_DISPLAY + H_FRONT and h_count < H_DISPLAY + H_FRONT + H_SYNC) else '1';

    --On abaisse le signal de synchronisation verticale à 0 lorsque le compteur vertical
    --est entre V_DISPLAY + V_FRONT_PORCH et V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE
    vsync <= '0' when (v_count >= V_DISPLAY + V_FRONT and v_count < V_DISPLAY + V_FRONT + V_SYNC) else '1';

    -- Vidéo visible uniquement pendant la zone d’affichage
    video_on <= '1' when (h_count < H_DISPLAY and v_count < V_DISPLAY) else '0';
    pixel_x  <= std_logic_vector(to_unsigned(h_count, 11));
    pixel_y  <= std_logic_vector(to_unsigned(v_count, 10));
end Behavioral;
