--[[ The function, MakeInclTypeFile, will create a header file containing the OpenGL typdefs and preprocessor machinery



It takes these parameters:
- the name of the output file. Without the path.
- the specData, as formatted by LoadLuaSpec.
- an array of strings to write to the front of the header file.
]]

require "_util"
require "_makeHelpers"


function MakeInclTypeFile(outFilename, specData, preceedData)
	
	local hFile = io.open(GetIncludePath() .. outFilename .. ".h", "w");
	if(not hFile) then
		print("Could not open the output file\"" .. GetIncludePath() .. outFilename .. "\".\n");
		return;
	end
	
	local defineName = string.upper(outFilename) .. "_H";
	
	hFile:write(GetFileIncludeGuardStart(defineName));
	hFile:write("\n");
	
	if(preceedData) then
		for i, preceed in ipairs(preceedData) do
			hFile:write(preceed);
			hFile:write("\n");
		end
	end
	
	--Write the passthru data.
	for i, passthru in ipairs(specData.funcData.passthru) do
		hFile:write(passthru);
		hFile:write("\n");
	end
	hFile:write("\n");

	--Write post data.
	if(preceedData and preceedData.footer) then
		for i, footer in ipairs(preceedData.footer) do
			hFile:write(footer);
			hFile:write("\n");
		end
	end
	
	hFile:write(GetFileIncludeGuardEnd(defineName));
	
	hFile:close();
end

