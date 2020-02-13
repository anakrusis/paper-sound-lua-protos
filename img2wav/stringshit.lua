-- This library deals with exporting numerical values as strings in a file
-- It does so by converting them to hex, and parsing two hex digits at a time, 8 bit chunx

endianness = "l"

function tostr_W(num,length) -- to string of WIDTH (in bytes)

	-- converts a number to a string value with the right byte width.
	
	temp = string.format("%x",num) -- converts to hex string first
	
	-- no odd string lengths. concatenates a 0 if the string has an odd number of chars
	if temp:len()%2 == 1 then
		temp = "0" .. temp
	end
	
	--if num>255 then
	--	local bytes = 1 -- i is the number of bytes neded
	--	output = ""
	--	
	--	while num%256^bytes ~= num do -- find the least number of bytes needed to represent the digit
	--		bytes=bytes+1
	--	end
	--	
	--	for i=1,bytes do
	--		temp = math.floor(num/16^i)
	--		output = output + string.char(temp)
	--	end	
	--	
	--	print(output)
	--	return string.char(0):rep(length-bytes) .. string.char(output)
	--else	
	output = ""
	
	if endianness == "b" then
		start = 1
		stop = temp:len()-1
		inc = 2
	elseif endianness == "l" then
		start = temp:len()-1
		stop = 1
		inc = -2
	end
	
	for i=start,stop,inc do
		currentstring = string.sub(temp,i,i+1)
		output = output .. string.char(tonumber(currentstring,16))
	end
	
	if output:len() < length then
		if endianness == "b" then
			return string.char(0):rep(length-output:len()) .. output
		elseif endianness == "l" then
			return output .. string.char(0):rep(length-output:len())
		end
	end
end