library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_vga is
    Port (
        clk       : in  STD_LOGIC;  -- 65 MHz
        reset     : in  STD_LOGIC;
        hsync     : out STD_LOGIC;
        vsync     : out STD_LOGIC;
        red       : out STD_LOGIC_VECTOR(3 downto 0);
        green     : out STD_LOGIC_VECTOR(3 downto 0);
        blue      : out STD_LOGIC_VECTOR(3 downto 0);
        pixel_y   : out STD_LOGIC_VECTOR(9 downto 0)  -- Ajouté pour visualisation
    );
end top_vga;

architecture Structural of top_vga is

    signal pixel_x    : STD_LOGIC_VECTOR(10 downto 0);
    signal pixel_y_int: STD_LOGIC_VECTOR(9 downto 0);
    signal video_on   : STD_LOGIC;

begin

    vga_ctrl : entity work.vga_controller
        port map (
            clk      => clk,
            reset    => reset,
            hsync    => hsync,
            vsync    => vsync,
            video_on => video_on,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y_int
        );

    vga_gen : entity work.vga_pattern
        port map (
            pixel_x  => pixel_x,
            pixel_y  => pixel_y_int,
            video_on => video_on,
            red      => red,
            green    => green,
            blue     => blue
        );

    -- Connexion du signal interne à la sortie
    pixel_y <= pixel_y_int;

end Structural;