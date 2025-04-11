library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_vga_controller is
end tb_vga_controller;

architecture Behavioral of tb_vga_controller is

    -- Composant à tester
    component vga_controller
        Port (
            clk        : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            hsync      : out STD_LOGIC;
            vsync      : out STD_LOGIC;
            video_on   : out STD_LOGIC;
            pixel_x    : out STD_LOGIC_VECTOR(10 downto 0);
            pixel_y    : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    -- Signaux de test
    signal clk       : STD_LOGIC := '0';
    signal reset     : STD_LOGIC := '1';
    signal hsync     : STD_LOGIC;
    signal vsync     : STD_LOGIC;
    signal video_on  : STD_LOGIC;
    signal pixel_x   : STD_LOGIC_VECTOR(10 downto 0);
    signal pixel_y   : STD_LOGIC_VECTOR(9 downto 0);

    constant CLK_PERIOD : time := 15.385 ns; -- 65 MHz

begin

    -- Génération d’horloge
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Instanciation du composant testé
    uut: vga_controller
        port map (
            clk       => clk,
            reset     => reset,
            hsync     => hsync,
            vsync     => vsync,
            video_on  => video_on,
            pixel_x   => pixel_x,
            pixel_y   => pixel_y
        );

    -- Stimulus principal
    stimulus: process
    begin
        wait for 100 ns;      -- reset initial
        reset <= '0';

        wait for 2 ms;        -- durée de simulation (ajuste si besoin)
        reset <= '1';
        wait;
    end process;

end Behavioral;
