library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top_vga is
end tb_top_vga;

architecture Behavioral of tb_top_vga is

    -- Composant à tester
    component top_vga
        Port (
            clk     : in  STD_LOGIC;
            reset   : in  STD_LOGIC;
            hsync   : out STD_LOGIC;
            vsync   : out STD_LOGIC;
            red     : out STD_LOGIC_VECTOR(3 downto 0);
            green   : out STD_LOGIC_VECTOR(3 downto 0);
            blue    : out STD_LOGIC_VECTOR(3 downto 0);
            pixel_y : out STD_LOGIC_VECTOR(9 downto 0)  -- ✅ ici on déclare proprement
        );
    end component;

    -- Signaux de test
    signal clk       : STD_LOGIC := '0';
    signal reset     : STD_LOGIC := '1';
    signal hsync     : STD_LOGIC;
    signal vsync     : STD_LOGIC;
    signal red       : STD_LOGIC_VECTOR(3 downto 0);
    signal green     : STD_LOGIC_VECTOR(3 downto 0);
    signal blue      : STD_LOGIC_VECTOR(3 downto 0);
    signal pixel_y   : STD_LOGIC_VECTOR(9 downto 0); -- ✅ déclaration du signal

    constant CLK_PERIOD : time := 15.385 ns;  -- 65 MHz

begin

    -- Génération de l'horloge
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Instanciation du top module
    uut: top_vga
        port map (
            clk     => clk,
            reset   => reset,
            hsync   => hsync,
            vsync   => vsync,
            red     => red,
            green   => green,
            blue    => blue,
            pixel_y => pixel_y         -- ✅ ici on connecte la sortie
        );

    -- Stimulus principal
    stim_proc : process
    begin
        wait for 100 ns;
        reset <= '0';

        wait for 20 ms; -- durée suffisante pour observer vsync
        reset <= '1';
        wait;
    end process;

end Behavioral;
