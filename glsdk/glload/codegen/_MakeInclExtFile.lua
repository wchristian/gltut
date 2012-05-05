--[[ The function, MakeInclExtFile, will create a header file containing the enums, extension test values, and the list of function pointers for all OpenGL extensions. It will create a C and C++ version

It takes these parameters:
- the name of the output file. Without the path.
- the specData, as formatted by LoadLuaSpec.
- the prefix (without the underscore) to prepend to enumerators.
- the prefix to prepend to functions.
- an array of strings to write to the front of the header file.
]]

require "_util"
require "_makeHelpers"

local function ProcessExtensionC(hFile, ext, extName, specData,
							enumPrefix, funcPrefix)
	WriteFormatted(hFile, GetSectionHeading(string.format("Extension: %s_%s",
		enumPrefix, extName)));
	hFile:write("\n");
	
	--Write the enumerators.
	for i, enum in ipairs(ext.enums) do
		hFile:write(Make.GetEnumerator(enum, specData.enumtable, enumPrefix), "\n");
	end

	if(#ext.funcs ~= 0) then
		if(#ext.enums ~= 0 and #ext.funcs ~= 0) then
			hFile:write("\n\n");
		end
		
		--Write the typedefs.

		--Write the #ifdef for the function pointers, so that they are only
		--available if something hasn't defined over them.
		local extDefine = string.format("%s_%s", enumPrefix, extName);
		hFile:write(string.format("#ifndef %s\n#define %s 1\n\n",
			extDefine, extDefine));
		
		for i, func in ipairs(ext.funcs) do
			hFile:write(Make.GetFuncTypedef(func, funcPrefix, specData.typemap));
			hFile:write("\n");
		end
		
		hFile:write("\n");
		
		--Write the function pointers.
		for i, func in ipairs(ext.funcs) do
			if(specData.coreexts[extName]) then
				hFile:write(Make.GetCoreFuncExternPtr(func, funcPrefix, specData.typemap));
				hFile:write("\n");
				hFile:write(Make.GetCoreFuncPtrDefine(func, funcPrefix, specData.typemap));
			else
				hFile:write(Make.GetFuncExternPtr(func, funcPrefix, specData.typemap));
			end
			hFile:write("\n");
		end
		
		hFile:write(string.format("#endif /*%s*/", extDefine));
	end
		
	if(#ext.enums ~= 0 or #ext.funcs ~= 0) then
		hFile:write("\n\n");
	end
end

local function WriteFileC(outFilename, specData, enumPrefix, funcPrefix, preceedData)
	local hFile = io.open(GetIncludePath() .. outFilename .. ".h", "w");
	if(not hFile) then
		print("Could not open the output file\"" .. GetIncludePath() .. outFilename .. "\".\n");
		return;
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
	
	--Write the passthru data.
	for i, passthru in ipairs(specData.funcData.passthru) do
		hFile:write(passthru);
		hFile:write("\n");
	end
	hFile:write("\n");

	hFile:write(GetExternCStart());
	hFile:write("\n");
	
	--Write all of the extension query variables.
	for i, extName in ipairs(specData.extensions) do
		hFile:write(Make.GetExtensionVarExtern(extName, funcPrefix));
		hFile:write("\n");
	end

	hFile:write("\n\n");

	--Process all of the extensions.
	for extName, ext in sortPairs(specData.extdefs, CompLess) do
		ProcessExtensionC(hFile, ext, extName, specData, enumPrefix, funcPrefix);
	end
	
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

local function WriteExtCFunctions(hFile, ext, extName, specData, funcPrefix)
	--Write the typedefs.
	for i, func in ipairs(ext.funcs) do
		if(specData.coreexts[extName]) then
			hFile:write(Make.GetCoreFuncPtrDecl(func, funcPrefix, specData.typemap));
		else
			hFile:write(Make.GetFuncPtrDecl(func, funcPrefix, specData.typemap));
		end
		hFile:write("\n");
	end
end

local function WriteExtEnums(hFile, ext, extName, specData, enumPrefix, writtenEnum)
	if(#ext.enums ~= 0) then
		WriteFormatted(hFile, GetSectionHeading(string.format("Extension: %s_%s",
			enumPrefix, extName)));
	end
		
	for i, enum in ipairs(ext.enums) do
		if(writtenEnum[enum.name]) then
			hFile:write("//\t\t", 
				Make.GetEnumeratorCpp(enum, specData.enumtable, "GL"),
				" From: ",
				writtenEnum[enum.name],
				"\n");
		else
			hFile:write("\t\t",
				Make.GetEnumeratorCpp(enum, specData.enumtable, enumPrefix),
				"\n");
				writtenEnum[enum.name] = extName;
		end
	end
	
	if(#ext.enums ~= 0) then
		hFile:write("\n");
	end
end

local function WriteExtFunctions(hFile, ext, extName, specData,
						enumPrefix, funcPrefix)
	if(#ext.funcs ~= 0) then
		WriteFormatted(hFile, GetSectionHeading(string.format("Extension: %s_%s",
			enumPrefix, extName)));
	end
	
	for i, func in ipairs(ext.funcs) do
		if(specData.coreexts[extName]) then
			hFile:write("\t",
				Make.GetFuncDefCpp(func, funcPrefix, specData.typemap, true),
				"\n");
		else
			hFile:write("\t",
				Make.GetFuncDefCpp(func, funcPrefix, specData.typemap, false),
				"\n");
		end
	end
	
	if(#ext.funcs ~= 0) then hFile:write("\n") end
end

local function WriteFileCpp(outFilename, specData, enumPrefix,
					funcPrefix, preceedData)
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

	--Write all of the extension query variables.
	for i, extName in ipairs(specData.extensions) do
		hFile:write(Make.GetExtensionVarExtern(extName, "gl"));
		hFile:write("\n");
	end
	
	--Process all of the extensions, creating all of the function pointer varaibles for them.
	for extName, ext in sortPairs(specData.extdefs, CompLess) do
		WriteExtCFunctions(hFile, ext, extName, specData, funcPrefix);
	end

	hFile:write(GetExternCEnd(), "\n");

	hFile:write("\nnamespace " .. funcPrefix .. "\n{\n");

	--Write the enumerators.
	hFile:write("\tenum " .. outFilename .. "\n\t{\n");

	local writtenEnum = {}
	for extName, ext in sortPairs(specData.extdefs, CompLess) do
		WriteExtEnums(hFile, ext, extName, specData, enumPrefix, writtenEnum);
	end

	hFile:write("\t};\n\n");
	
	for extName, ext in sortPairs(specData.extdefs, CompLess) do
		WriteExtFunctions(hFile, ext, extName, specData, enumPrefix, funcPrefix);
	end

	hFile:write("\n}\n\n");

	--[=[
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
	]=]
	
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

function MakeInclExtFile(outFilename, specData, enumPrefix, funcPrefix, preceedData)
	WriteFileC(outFilename, specData, enumPrefix, funcPrefix, preceedData);
	WriteFileCpp(outFilename, specData, enumPrefix, funcPrefix, preceedData);
end

