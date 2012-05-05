--[[The function, MakeInclCoreFile, will create a C and C++ header file containing the enums and function pointers for a given core version. It will only put those definitions which were added to that particular core version. So definitions that were added to OpenGL in past versions are not included. Core extensions are also not included.

If it is given a removal version, then it will only output the enums and functions that were both a part of the given core version *and* removed in the given removal version. If no removal version is given, then it will only output the definitions that are still core in the most recent OpenGL version.

If the function returns false, then there are no enums and functions for the given core and removal versions. Otherwise, it will return true.

It takes these parameters:
- the name of the output file. Without the path.
- the specData, as formatted by LoadLuaSpec.
- the prefix (without the underscore) to prepend to enumerators.
- the prefix to prepend to functions.
- a string representing the specific GL version to export. Only those funcs and enums will be written.
- a string representing the removal version. It will only write funcs and enums that were removed in that version. If nil, then will write only core.
- an array of strings to write to the front of the header file.
]]

require "_util"
require "_makeHelpers"

local function ProcessCoreVersionC(hFile, enumList, funcList, specData, enumPrefix,
									funcPrefix, targetVersion)
	hFile:write("\n");
end

local function CollateWrittenData(hFile, core, specData, targetVersion, removeVersion)
	local enumList = {};
	if(removeVersion) then
		removeVersion = tonumber(removeVersion);
	end
	for i, enum in ipairs(core.enums) do
		local bShouldWrite = true;
		if(removeVersion) then
			--We're writing only enums from targetVersion that were removed
			--in removeVersion.
			if(not enum.removed or
				(tonumber(enum.removed) ~= removeVersion))
			then
				bShouldWrite = false;
			end
		else
			--We're writing core only. If it was removed in any version, don't write.
			if(enum.removed) then
				bShouldWrite = false;
			end
		end
		
		--We'll write it as an extension
		if(enum.extensions) then
			bShouldWrite = false;
		end
		
		if(bShouldWrite) then
			enumList[#enumList + 1] = enum;
		end
	end
	
	--Collate the functions we want to write.
	local funcList = {};
	for i, func in ipairs(core.funcs) do
		local bShouldWrite = true;
		if(removeVersion) then
			--We're writing only functions from targetVersion that were removed
			--in removeVersion.
			if(not func.deprecated or
				(tonumber(func.deprecated) ~= removeVersion))
			then
				bShouldWrite = false;
			end
		else
			--We're writing core only. If it was removed in any version, don't write.
			if(func.deprecated) then
				bShouldWrite = false;
			end
		end
		
		--Exts don't start with "VERSION"; don't write extension
		--functions here. Write them in the extension
		if(func.category and not string.match(func.category, "^VERSION")) then
			bShouldWrite = false;
		end
		
		if(bShouldWrite) then
			funcList[#funcList + 1] = func;
		end
	end
	
	return enumList, funcList;
end

local function WriteFileC(outFilename, enumList, funcList, specData, enumPrefix,
					funcPrefix, targetVersion, removeVersion, preceedData)
	local hFile = io.open(GetIncludePath() .. outFilename .. ".h", "w");
	if(not hFile) then
		print("Could not open the output file\"" .. GetIncludePath() .. outFilename .. "\".\n");
		return false;
	end
	
	--Write the basic starting data.
	local defineName = string.upper(outFilename) .. "_H";
	hFile:write(GetFileIncludeGuardStart(defineName));
	hFile:write("\n");
	
	if(preceedData) then
		for i, preceed in ipairs(preceedData) do
			hFile:write(preceed);
			hFile:write("\n");
		end
	end
	hFile:write("\n");

	hFile:write(GetExternCStart());
	hFile:write("\n");
	
	--Write the enumerators.
	for i, enum in ipairs(enumList) do
		hFile:write(Make.GetEnumerator(enum, specData.enumtable, enumPrefix));
		hFile:write("\n");
	end
	
	--Write the typedefs.
	for i, func in ipairs(funcList) do
		hFile:write(Make.GetFuncTypedef(func, funcPrefix, specData.typemap));
		hFile:write("\n");
	end

	hFile:write("\n");
	
	--Write the function pointers.
	for i, func in ipairs(funcList) do
		hFile:write(Make.GetCoreFuncExternPtr(func, funcPrefix, specData.typemap));
		hFile:write("\n");
		hFile:write(Make.GetCoreFuncPtrDefine(func, funcPrefix, specData.typemap));
		hFile:write("\n");
	end
	
	hFile:write("\n\n");
	
	--End the file.
	hFile:write(GetExternCEnd());
	hFile:write("\n");
	
	if(preceedData and preceedData.footer) then
		for i, footer in ipairs(preceedData.footer) do
			hFile:write(footer);
			hFile:write("\n");
		end
	end
	
	hFile:write(GetFileIncludeGuardEnd(defineName));
	
	hFile:close();
end

local function WriteFileCpp(outFilename, enumList, funcList, specData,
					enumPrefix, funcPrefix, targetVersion, removeVersion,
					preceedData)
	local hFile = io.open(GetIncludePath() .. outFilename .. ".hpp", "w");
	if(not hFile) then
		print("Could not open the output file\"" .. GetIncludePath() .. outFilename .. "\".\n");
		return false;
	end
	
	--Write the basic starting data.
	local defineName = string.upper(outFilename) .. "_HPP";
	hFile:write(GetFileIncludeGuardStart(defineName));
	hFile:write("\n");
	
	if(preceedData) then
		for i, preceed in ipairs(preceedData) do
			hFile:write(preceed);
			hFile:write("\n");
		end
	end
	hFile:write("\n");
	
	hFile:write(GetExternCStart(), "\n");

	--Write C function pointers.
	for i, func in ipairs(funcList) do
		hFile:write(Make.GetCoreFuncPtrDecl(func, "gl", specData.typemap), "\n");
	end
	
	hFile:write(GetExternCEnd(), "\n");

	hFile:write("\nnamespace " .. funcPrefix .. "\n{\n");

	--Write the enumerators.
	hFile:write("\tenum " .. outFilename .. "\n\t{\n");

	for i, enum in ipairs(enumList) do
		hFile:write("\t\t",
			Make.GetEnumeratorCpp(enum, specData.enumtable, enumPrefix),
			"\n");
	end

	hFile:write("\t};\n\n");
	
	--Write the inline functions.
	for i, func in ipairs(funcList) do
		hFile:write("\t",
			Make.GetFuncDefCpp(func, funcPrefix, specData.typemap, true),
			"\n");
	end

	hFile:write("\n}\n\n");
	
	--End the file.
	if(preceedData and preceedData.footer) then
		for i, footer in ipairs(preceedData.footer) do
			hFile:write(footer);
			hFile:write("\n");
		end
	end
	
	hFile:write(GetFileIncludeGuardEnd(defineName));
	
	hFile:close();
end


function MakeInclCoreFile(outFilename, specData, enumPrefix, funcPrefix,
							targetVersion, removeVersion, preceedData)
	local enumList, funcList;

	local coreVersions = dofile(GetDataFilePath() .. "listOfCoreVersions.lua");
	if(not targetVersion) then targetVersion = coreVersions[#coreVersions]; end;

	for i, version in ipairs(coreVersions) do
		if(specData.coredefs[version] and
			(tonumber(version) == tonumber(targetVersion)))
		then
			enumList, funcList = 
				CollateWrittenData(hFile, specData.coredefs[version], specData,
				targetVersion, removeVersion);
			break;
		end
	end
	
	if(#enumList == 0 and #funcList == 0) then
		return false;
	end

	WriteFileC(outFilename, enumList, funcList, specData, enumPrefix,
		funcPrefix, targetVersion, removeVersion, preceedData);
	
	WriteFileCpp(outFilename, enumList, funcList, specData, enumPrefix,
		funcPrefix, targetVersion, removeVersion, preceedData);
	
	return true;
end

