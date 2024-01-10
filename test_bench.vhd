--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:56:05 11/22/2023
-- Design Name:   
-- Module Name:   /home/student1/ymadhu/Courses/7th-sem/COE-758/Design_Project_2/test_bench.vhd
-- Project Name:  Design_Project_2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: VGA_Driver
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY test_bench IS
END test_bench;
 
ARCHITECTURE behavior OF test_bench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT VGA_Driver
    PORT(
         clk : IN  std_logic;
         clk25 : OUT  std_logic;
         rst : IN  std_logic;
         H : OUT  std_logic;
         V : OUT  std_logic;
         Rout : OUT  std_logic_vector(7 downto 0);
         Gout : OUT  std_logic_vector(7 downto 0);
         Bout : OUT  std_logic_vector(7 downto 0);
         isDrawOut : OUT  bit;
         hPosOut : OUT  integer;
         vPosOut : OUT  integer;
			cycleOut : OUT integer;
			SW0		: in std_logic;
			SW1		: in std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';

 	--Outputs
   signal clk25 : std_logic;
   signal H : std_logic;
   signal V : std_logic;
   signal Rout : std_logic_vector(7 downto 0);
   signal Gout : std_logic_vector(7 downto 0);
   signal Bout : std_logic_vector(7 downto 0);
   signal isDrawOut : bit;
   signal hPosOut : integer;
   signal vPosOut : integer;
	signal cycleOut : integer;

   -- Clock period definitions
   constant clk_period : time := 20 ns;
	
	signal SW0 : std_logic := '0';
	signal SW1 : std_logic := '0';

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: VGA_Driver PORT MAP (
          clk => clk,
          clk25 => clk25,
          rst => rst,
          H => H,
          V => V,
          Rout => Rout,
          Gout => Gout,
          Bout => Bout,
          isDrawOut => isDrawOut,
          hPosOut => hPosOut,
          vPosOut => vPosOut,
			 cycleOut => cycleOut,
			 SW0 => SW0,
			 SW1 => SW1
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

 END;
