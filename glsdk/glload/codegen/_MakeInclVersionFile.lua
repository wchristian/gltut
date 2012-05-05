--[[ The function, MakeInclVersionFile, will create a header file that includes all of the headers it is given. It will create a C and C++ version

It takes these parameters:
- the name of the output file. Without the path.
- the list of files to include. Without the file name extension.
]]

require "_util"
require "_makeHelpers"

local function WriteFileC(outFilename, includeList)
	local hFile = io.open(GetIncludePath() .. outFilename .. ".h", "w");
	if(not hFile) then
		print("Could not open the output file\"" .. GetIncludePath() .. outFilename .. "\".\n");
		return false;
	end

	local defineName = string.upper(outFilename) .. "_H";
	hFile:write(GetFileIncludeGuardStart(defineName));

	for i, include in ipairs(includeList) do
		hFile:write("#include \"", include, ".h\"\n");
	end
	
	hFile:write("\n", GetFileIncludeGuardEnd(defineName));
	hFile:close();
end

local function WriteFileCpp(outFilename, includeList)
	local hFile = io.open(GetIncludePath() .. outFilename .. ".hpp", "w");
	if(not hFile) then
		print("Could not open the output file\"" .. GetIncludePath() .. outFilename .. "\".\n");
		return false;
	end
	
	local defineName = string.upper(outFilename) .. "_HPP";
	hFile:write(GetFileIncludeGuardStart(defineName));

	for i, include in ipairs(includeList) do
		--HACK! The first one is always a .h.
		if(i == 1) then
			hFile:write("#include \"", include, ".h\"\n");
		else
			hFile:write("#include \"", include, ".hpp\"\n");
		end
	end
	
	hFile:write("\n", GetFileIncludeGuardEnd(defineName));
	hFile:close();
end


function MakeInclVersionFile(outFilename, includeList)
	WriteFileC(outFilename, includeList)
	WriteFileCpp(outFilename, includeList)
end