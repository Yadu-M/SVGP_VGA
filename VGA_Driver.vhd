----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:59:04 11/17/2023 
-- Design Name: 
-- Module Name:    VGA_Driver - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VGA_Driver is

Port (
	clk 		: in std_logic;
	clk25		: out std_logic;
	rst 		: in std_logic;
	H 			: out std_logic;
	V 			: out std_logic;
	Rout 		: out std_logic_vector(7 downto 0);
	Gout 		: out std_logic_vector(7 downto 0);
	Bout 		: out std_logic_vector(7 downto 0);
	isDrawOut: out bit;
	hPosOut	: out integer;
	vPosOut	: out integer;
	cycleOut	: out integer;
	SW0		: in std_logic;
	SW1		: in std_logic
	);	

end VGA_Driver;

architecture Behavioral of VGA_Driver is

	signal clk25_set : std_logic := '0'; 
	
	constant h_complete_line 	: integer := 800;
	constant h_front_porch 		: integer := 16;
	constant h_sync_pulse 		: integer := 96;
	constant h_back_porch 		: integer := 48; 
	constant h_active_area 		: integer := 640;

	constant v_complete_frame 	: integer := 525;
	constant v_front_porch	 	: integer := 10;
	constant v_sync_pulse	 	: integer := 2;
	constant v_back_porch	 	: integer := 33;
	constant v_active_area 		: integer := 480;
	
	signal hPos 					: integer := 1; 
	signal vPos 					: integer := 1;
	
	signal isDraw					: bit := '0';
	
	-- Color declarations
	constant bg_colour_r			: std_logic_vector := "00000000";
	constant bg_colour_g			: std_logic_vector := "10011001";
	constant bg_colour_b			: std_logic_vector := "01001100";
	
	constant white					: std_logic_vector := "11111111";
	constant black					: std_logic_vector := "00000000";
	
	constant shadow				: std_logic_vector := "01000000";
		
	-- Padding/Margin/Size declarations
	constant actual_padding		: integer := 30;
	
	constant top_padding			: integer := (v_sync_pulse + v_back_porch + actual_padding);
	constant bot_padding			: integer := (v_complete_frame - v_front_porch - actual_padding);
	constant left_padding		: integer := (h_sync_pulse + h_back_porch + actual_padding);
	constant right_padding 		: integer := (h_complete_line - h_front_porch - actual_padding);

	constant border_size			: integer := 16;
	
	constant border_length		: integer := (bot_padding - top_padding);
	constant border_width		: integer := (right_padding - left_padding);
	
	constant goal_size			: integer := 150;

	constant mid_line_width		: integer := (border_size/4);
	constant mid_line_gap		: integer := 8;
	constant mid_line_length	: integer := 64;
	
	signal ball_v					: integer := (top_padding + (border_length / 2));
	signal ball_h					: integer := (left_padding + (border_width / 2));
	constant ball_size			: integer := 8;
	
	constant paddle_width		: integer := border_size;
	constant paddle_length		: integer := (goal_size - 60);
	signal l_paddle_v				: integer := (top_padding + (border_length/2));	
	constant l_paddle_h				: integer := (left_padding + border_size + (actual_padding/2) + border_size);
	signal r_paddle_v				: integer := (top_padding + (border_length/2));
	constant r_paddle_h				: integer := (right_padding - border_size - (actual_padding/2) - border_size);
	constant upper_limit			: integer := (top_padding + border_size + (paddle_length/2));
	constant lower_limit			: integer := (bot_padding - border_size - (paddle_length/2));

	
--	signal clk_cycle				: std_logic_vector (24 downto 0) := x"0000000";
	
	signal clk_cycle				: integer := -50000000;
	constant clk_rate				: integer := 49000*60;   -- clk rate or total clock number for 1 sec
	
	signal direction				: string(1 to 2) := "br";     -- a is br, b is tr, c - 
	
	
	
begin
	

	clk_div : process (clk)	-- Clock divider / setting up 25 MHz clock
	begin
		if (clk'event and clk ='1') then 		
			clk25_set <= not clk25_set;
		end if;	
	end process;
	
	
	hPos_Counter : process(clk25_set, rst)  -- Incrementing Horizontal position per pixel
	begin
		if (rst = '1') then
			hPos <= 0;
		elsif (clk25_set'event and clk25_set='1') then
			if (hPos = h_complete_line) then
				hPos <= 1;
			else
				hPos <= hPos + 1;
			end if;
		end if;
	end process;
	
	
	vPos_counter : process(clk25_set, rst, hPos, vPos) -- Incrementing Vertical position per pixel
	begin
		if (rst = '1') then
			vPos <= 0;
		elsif (clk25_set'event and clk25_set='1') then
			if (hPos = h_complete_line) then
				if (vPos = v_complete_frame) then
					vPos <= 1;
				else
					vPos <= vPos + 1;
				end if;
			end if;			
		end if;
	end process;
	
	
	hSync : process(clk25_set, rst, hPos, vPos)	-- Applying Hsync signal
	begin
		if (rst = '1') then
			H <= '0';
		elsif (clk25_set'event and clk25_set='1') then
			if ((hPos > h_sync_pulse) and (hPos < h_complete_line)) then
				H <= '1';
			else
				H <= '0';
			end if;
		end if;
	end process;
	
	
	vSync : process(clk25_set, rst, vPos, hPos)  -- Applying Vsync signal
	begin
		if (rst = '1') then
			V <= '0';
		elsif (clk25_set'event and clk25_set='1') then
			if ((vPos > v_sync_pulse) and (vPos < v_complete_frame)) then
				V <= '1';
			else
				V <= '0';
			end if;
		end if;
	end process;
	
	
	
	ifDraw : process(clk25_set, rst, hPos, vPos)   -- Updating Draw signal timings to indicate whether RGB values can be HIGH or not
	begin
		if (rst = '1') then
			isDraw <= '0';
		elsif (clk25_set'event and clk25_set='1') then
			if ((vPos > (v_sync_pulse + v_back_porch)) and (vPos < (v_complete_frame - v_front_porch))) then
				if ((hPos > (h_sync_pulse + h_back_porch)) and (hPos < (h_complete_line - h_front_porch))) then
					isDraw <= '1';
				else 
					isDraw <= '0';
				end if;
			else
				isDraw <= '0';
			end if;
		end if;
	end process;
	
	
	vidOut : process(clk25_set, rst, hPos, vPos, isDraw, ball_v, ball_h, SW0)  -- Drawing function
	begin

		if (rst = '1') then			
			Rout <= "00000000";
			Gout <= "00000000";
			Bout <= "00000000";
		elsif (clk25_set'event and clk25_set='1') then
			if (clk_cycle = 0) then
				direction <= "br";
			end if;
			clk_cycle <= clk_cycle + 1;		
			
			if (isDraw = '1') then
				if (((vPos > top_padding) and (vPos < (top_padding + border_size))) -- condition for top border (horizontal)
						or
					((vPos < bot_padding) and (vPos > (bot_padding - border_size)))  -- condition for bottom border (horizontal)
				) then -- horizontal Borders
					if ((hPos > left_padding) and (hPos < (right_padding))) then	  -- condition for left/right padding for top border 				
						Rout <= white;
						Gout <= white;
						Bout <= white;
					else
						Rout <= bg_colour_r;
						Gout <= bg_colour_g;
						Bout <= bg_colour_b;
					end if;
					
				
				elsif (
					((hPos > left_padding) and (hPos < (left_padding + border_size)))		 -- condition for left border (vertical)
						or
					((hPos < (right_padding)) and (hPos > (right_padding - border_size))) -- condition for right border (vertical)
					) then -- Vertical Borders
						if (((vPos > top_padding) and (vPos < (top_padding + ((border_length/2) - (goal_size/2))))) 
							or 
							((vPos < bot_padding) and (vPos > (top_padding + ((border_length/2) + (goal_size/2)))))
					) then
							Rout <= white;
							Gout <= white;
							Bout <= white;
						end if;
				elsif (
					((vPos >= (top_padding + border_size)) and (vPos <= (bot_padding - border_size))) 
				and 
					((hPos > (left_padding + ((border_width/2) - (mid_line_width/2)))) and (hPos < (left_padding + ((border_width/2) + (mid_line_width/2)))))
				)then		
					if ((mid_line_gap < ((vPos - top_padding - border_size) mod mid_line_length))) then -- midline border drawing
						Rout <= shadow;
						Gout <= shadow;
						Bout <= shadow;	
					end if;
--				elsif((vPos > (top_padding +((border_length/2) - (paddle_length/2)))) and (vPos < (top_padding + ((border_length/2) + (paddle_length/2))))) then
--					if ((hPos > (left_padding + border_size + (actual_padding/2))) and (hPos < (left_padding + border_size + (actual_padding/2) + paddle_width))) then
--						Rout <= white;				-- Drawing Left Paddle
--						Gout <= "01100110";
--						Bout <= "11001100";
--					elsif ((hPos < (right_padding - border_size - (border_size/2))) and (hPos > (right_padding - border_size - (border_size/2) - paddle_width))) then
--						Rout <= "01111111";		-- Drawing Right Paddle
--						Gout <= white;
--						Bout <= "11111111";
--					else
--						Rout <= bg_colour_r;
--						Gout <= bg_colour_g;
--						Bout <= bg_colour_b;
--					end if;
						
				else
				
					Rout <= bg_colour_r;
					Gout <= bg_colour_g;
					Bout <= bg_colour_b;
				end if;
				
				
--				

				if (
				((vPos >= (l_paddle_v - (paddle_length/2))) and (vPos <= (l_paddle_v + (paddle_length/2))))
					and 
				((hPos >= (l_paddle_h - (paddle_width/2))) and (hPos <= (l_paddle_h + (paddle_width/2))))
				) then
					Rout <= white;				-- Drawing Left Paddle
					Gout <= "01100110";
					Bout <= "11001100";					
				end if;
				
				if (
				((vPos >= (r_paddle_v - (paddle_length/2))) and (vPos <= (r_paddle_v + (paddle_length/2))))
					and 
				((hPos >= (r_paddle_h - (paddle_width/2))) and (hPos <= (r_paddle_h + (paddle_width/2))))
				) then
					Rout <= "01111111";		-- Drawing Right Paddle
					Gout <= white;
					Bout <= "11111111";
				end if;

				
				
				if (
					((ball_v > (top_padding + (border_length/2) - (goal_size/2))) and (ball_v < (top_padding + (border_length/2) + (goal_size/2))))
					and 
					(((ball_h - ball_size) <= (left_padding + border_size)) or ((ball_h + ball_size) >= (right_padding - border_size)))
					) then
						
						if (
						((vPos > (ball_v - ball_size)) and (vPos < (ball_v + ball_size)))
							and
						((hPos > (ball_h - ball_size)) and (hPos < (ball_h + ball_size)))
						) then -- Drawing ball					
								Rout <= "11111111";
								Gout <= "00000001";
								Bout <= "00000001";	
						
						
						end if;
						
						-- Reseting the ball
						
						if ((ball_h <= (left_padding + border_size)) or (ball_h >= (right_padding - border_size))) then
							ball_v <= (top_padding + (border_length / 2));
							ball_h <= (left_padding + (border_width / 2));
						end if;
--						if (ball_h <= (left_padding + border_size)) then
--							ball_v <= (top_padding + (border_length / 2));
--							ball_h <= (left_padding + (border_width / 2));
--						elsif (ball_h >= (right_padding - border_size)) then
--							ball_v <= (top_padding + (border_length / 2));
--							ball_h <= (left_padding + (border_width / 2));

						
					
				
				elsif (
				 ((ball_v + ball_size) = (bot_padding - border_size)) or ((ball_v - ball_size) = (top_padding + border_size))
				 or
				 ((ball_h - ball_size) = (left_padding + border_size)) or ((ball_h + ball_size) = (right_padding - border_size))
				 
				) then
					
						
					case direction is
						when "br" =>
							if ((ball_v + ball_size) = (bot_padding - border_size)) then
								direction <= "tr";
								ball_v <= ball_v - 1;
								ball_h <= ball_h + 1;
							else
								direction <= "bl";
								ball_v <= ball_v + 1;
								ball_h <= ball_h - 1;
							end if;
						when "tr" =>
							if ((ball_v - ball_size) = (top_padding + border_size)) then
								direction <= "br"; --br
								ball_v <= ball_v + 1;
								ball_h <= ball_h + 1;
							else 
								direction <= "tl";
								ball_v <= ball_v - 1;
								ball_h <= ball_h - 1;
							end if;
						when "tl" =>
							if ((ball_v - ball_size) = (top_padding + border_size)) then
								direction <= "bl";
								ball_v <= ball_v + 1;
								ball_h <= ball_h - 1;
							else 
								direction <= "tr";
								ball_v <= ball_v - 1;
								ball_h <= ball_h + 1;
							end if;
						when "bl" =>
							if ((ball_v + ball_size) = (bot_padding - border_size)) then
								direction <= "tl";
								ball_v <= ball_v - 1;
								ball_h <= ball_h - 1;
							else 
								direction <= "br";
								ball_v <= ball_v + 1;
								ball_h <= ball_h + 1;
							end if;
						when others => 
					end case;
				end if;
				

				-- Control ball speed

				if (clk_cycle >= (clk_rate/30)) then
--				 if (direction = "br") then
--					ball_v <= ball_v + 1;
--					ball_h <= ball_h + 1;
--				end if;

					clk_cycle <= 1;
					case direction is
						when "br" =>
							ball_v <= ball_v + 1;
							ball_h <= ball_h + 1;
						when "bl" =>
							ball_v <= ball_v + 1;
							ball_h <= ball_h - 1;
						when "tr" =>
							ball_v <= ball_v - 1;
							ball_h <= ball_h + 1;
						when "tl" =>
							ball_v <= ball_v - 1;
							ball_h <= ball_h - 1;
						when others =>
					
					end case;
					
					
					-- switch controls for paddles
					if (SW0 = '1') then
						l_paddle_v <= l_paddle_v - 1;
					else
						l_paddle_v <= l_paddle_v + 1;
					end if;
					
					if (SW1 = '1') then
						r_paddle_v <= r_paddle_v - 1;
					else
						r_paddle_v <= r_paddle_v + 1;
					end if;
					
					
					-- Setting the upper limit for paddles
					if (l_paddle_v = (top_padding + border_size + (paddle_length/2))) then
						l_paddle_v <= (upper_limit + 1);
					end if;
					
					if (r_paddle_v = (top_padding + border_size + (paddle_length/2))) then
						r_paddle_v <= (upper_limit + 1);
					end if;
					
					if (l_paddle_v = (bot_padding - border_size - (paddle_length/2))) then
						l_paddle_v <= (lower_limit - 1);
					end if;
					
					if (r_paddle_v = (bot_padding - border_size - (paddle_length/2))) then
						r_paddle_v <= (lower_limit  - 1);
					end if;
					
					if (
						(((l_paddle_v - (paddle_length/2)) <= (ball_v + ball_size)) and ((l_paddle_v + (paddle_length/2)) >= (ball_v - ball_size)))
						 and 
						 (((l_paddle_h + (paddle_width/2)) = (ball_h - ball_size)) or ((l_paddle_h - (paddle_width/2)) = (ball_h + ball_size)))						 
					) then
					
						if ((l_paddle_h + (paddle_width/2)) = (ball_h - ball_size)) then -- when it hits right side of left paddle
						
							case direction is
								when "bl" =>
									direction <= "br";
									ball_v <= ball_v + 1;
									ball_h <= ball_h + 1;
								when "tl" =>
									direction <= "tr";
									ball_v <= ball_v - 1;
									ball_h <= ball_h + 1;
								when others =>
							end case;
						end if;
						
						if ((l_paddle_h - (paddle_width/2)) = (ball_h + ball_size)) then -- when it hits left side of left paddle
							case direction is
								when "br" =>
									direction <= "bl";
									ball_v <= ball_v + 1;
									ball_h <= ball_h - 1;
								when "tr" =>
									direction <= "tl";
									ball_v <= ball_v - 1;
									ball_h <= ball_h - 1;
								when others => 
							end case;
						end if;
						
						if ((l_paddle_v + (paddle_width/2)) = (ball_v - ball_size)) then  -- when it hits bottomside of left paddle
							case direction is
								when "tl" =>
									direction <= "tr";
									ball_v <= ball_v - 1;
									ball_h <= ball_h + 1;
								when "tr" =>
									direction <= "tl";
									ball_v <= ball_v - 1;
									ball_h <= ball_h - 1;
								when others => 
							end case;
						end if;
						
						if ((l_paddle_v - (paddle_width/2)) = (ball_v + ball_size)) then  -- when it hits topside of left paddle
							case direction is
								when "br" =>
									direction <= "bl";
									ball_v <= ball_v + 1;
									ball_h <= ball_h - 1;
								when "bl" =>
									direction <= "br";
									ball_v <= ball_v + 1;
									ball_h <= ball_h + 1;
								when others =>
							end case;
						end if;
						
						
							
--						case direction is
--							when "bl" =>
--								direction <= "br";
--								ball_v <= ball_v + 1;
--								ball_h <= ball_h + 1;
--							when "tl" =>
--								direction <= "tr";
--								ball_v <= ball_v - 1;
--								ball_h <= ball_h + 1;
--							when "br" =>
--								direction <= "bl";
--								ball_v <= ball_v + 1;
--								ball_h <= ball_h - 1;
--							when "tr" =>
--								direction <= "tl";
--								ball_v <= ball_v - 1;
--								ball_h <= ball_h - 1;
--							when others =>
--						end case;
					end if;
					
					if (
						(((r_paddle_v - (paddle_length/2)) <= (ball_v + ball_size)) and ((r_paddle_v + (paddle_length/2)) >= (ball_v - ball_size)))
						 and 
						 (((r_paddle_h + (paddle_width/2)) = (ball_h - ball_size)) or ((r_paddle_h - (paddle_width/2)) = (ball_h + ball_size)))						 
					)then -- 
						if ((r_paddle_h + (paddle_width/2)) = (ball_h - ball_size)) then  -- when it hits right side of right paddle
							case direction is
								when "bl" =>
									direction <= "br";
									ball_v <= ball_v + 1;
									ball_h <= ball_h + 1;
								when "tl" =>
									direction <= "tr";
									ball_v <= ball_v - 1;
									ball_h <= ball_h + 1;
								when others =>
							end case;
							
						end if;
						
						if ((r_paddle_h - (paddle_width/2)) = (ball_h + ball_size)) then -- when it hits left side of right paddle
							case direction is
								when "br" =>
									direction <= "bl";
									ball_v <= ball_v + 1;
									ball_h <= ball_h - 1;
								when "tr" =>
									direction <= "tl";
									ball_v <= ball_v - 1;
									ball_h <= ball_h - 1;
								when others => 
							end case;
						end if;
						
						if ((r_paddle_v + (paddle_width/2)) = (ball_v - ball_size)) then  -- when it hits bottomside of right paddle
							case direction is
								when "tl" =>
									direction <= "tr";
									ball_v <= ball_v - 1;
									ball_h <= ball_h + 1;
								when "tr" =>
									direction <= "tl";
									ball_v <= ball_v - 1;
									ball_h <= ball_h - 1;
								when others => 
							end case;
						end if;
						
						if ((r_paddle_v - (paddle_width/2)) = (ball_v + ball_size)) then  -- when it hits topside of right paddle
							case direction is
								when "br" =>
									direction <= "bl";
									ball_v <= ball_v + 1;
									ball_h <= ball_h - 1;
								when "bl" =>
									direction <= "br";
									ball_v <= ball_v + 1;
									ball_h <= ball_h + 1;
								when others =>
							end case;
						end if;
					
					end if;
						
				end if;
				
				if (
				((vPos > (ball_v - ball_size)) and (vPos < (ball_v + ball_size)))
					and
				((hPos > (ball_h - ball_size)) and (hPos < (ball_h + ball_size)))
				) then -- Drawing ball					
						Rout <= "11111111";
						Gout <= "11111111";
						Bout <= "00000000";		
					
					
				end if;	
				
		
							
				
			else
				Rout <= "00000000";
				Gout <= "00000000";
				Bout <= "00000000";
				
				
			end if;
		end if;

	end process;
	
	-- Output extra outputs signals for observing purposes.
	isDrawOut <= isDraw;	
	hPosOut <= hPos;
	vPosOut <= vPos;
	clk25 <= clk25_set;
	cycleOut <= clk_cycle;

	
end Behavioral;
