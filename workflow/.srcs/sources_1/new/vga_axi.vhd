----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/04/2025 12:17:58 PM
-- Design Name: 
-- Module Name: vga_axi - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_axi is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           s_axis_tvalid : in STD_LOGIC;
           s_axis_tdata : in STD_LOGIC_VECTOR (11 downto 0);
           s_axis_tlast : in STD_LOGIC;
           s_axis_tready : out STD_LOGIC;
           hsync : out STD_LOGIC;
           vsync : out STD_LOGIC;
           rgb : out STD_LOGIC_VECTOR (11 downto 0));
end vga_axi;

architecture Behavioral of vga_axi is

begin


end Behavioral;
