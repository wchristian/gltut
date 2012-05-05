--[[
Calling dofile on this will generate all of the header and source files needed
for GLE.
]]

require "_LoadLuaSpec"
require "_MakeExtHeaderFile"
require "_MakeMainHeaderFile"
require "_MakeMainSourceFile"
require "_MakeCoreHeaderFile"
require "_MakeCoreSourceFile"
require "_MakeInclTypeFile"
require "_MakeInclCoreFile"
require "_MakeInclExtFile"
require "_MakeInclVersionFile"
require "_util"

local specFileLoc = GetSpecFilePath();



---------------------------
--Create standard OpenGL files.
local specData = LoadLuaSpec(specFileLoc .. "glspec.lua");
	
local glPreceedData = {
		dofile(GetDataFilePath() .. "headerGlProtect.lua"),
		dofile(GetDataFilePath() .. "glDefStr.lua"),
		dofile(GetDataFilePath() .. "headerFunc.lua"),
	}

--Write the external headers.
local glOutputs = {
	{"gl_2_1", "2.1", true},
	{"gl_3_0", "3.0", true},
	{"gl_3_1", "3.1", true},
	{"gl_3_1_comp", "3.1", false},
	{"gl_3_2", "3.2", true},
	{"gl_3_2_comp", "3.2", false},
	{"gl_3_3", "3.3", true},
	{"gl_3_3_comp", "3.3", false},
	{"gl_4_0", "4.0", true},
	{"gl_4_0_comp", "4.0", false},
	{"gl_4_1", "4.1", true},
	{"gl_4_1_comp", "4.1", false},
	{"gl_4_2", "4.2", true},
	{"gl_4_2_comp", "4.2", false},
};

local glTruncPreceedData = {}

local removalVersions = { "3.1" }
local listOfCoreVersions = dofile(GetDataFilePath() .. "listOfCoreVersions.lua");
local newGlOutputs = {};

local function GetCoreInclBasename(coreVersion, removalVersion)
	local baseName = "_int_gl_" .. coreVersion:gsub("%.", "_");
	if(removalVersion) then
		baseName = baseName .. "_rem_" .. removalVersion:gsub("%.", "_");
	end
	return baseName;
end

for i, coreVersion in ipairs(listOfCoreVersions) do
	local baseFilename = GetCoreInclBasename(coreVersion);
	local output = {};
	output[1] = baseFilename;
	output[2] = coreVersion;
	output[3] = nil;
	newGlOutputs[baseFilename] = output;
	for i, removalVersion in ipairs(removalVersions) do
		output = {};
		local newFilename = GetCoreInclBasename(coreVersion, removalVersion);
		output[1] = newFilename;
		output[2] = coreVersion;
		output[3] = removalVersion;
		newGlOutputs[newFilename] = output;
	end
end

local typeHeaderName = "_int_gl_type";
local extHeaderName = "_int_gl_exts";

MakeInclTypeFile(typeHeaderName, specData, glPreceedData);

for baseFilename, output in pairs(newGlOutputs) do
	output[4] = MakeInclCoreFile(output[1], specData, "GL", "gl",
		output[2], output[3], glTruncPreceedData);
end

MakeInclExtFile(extHeaderName, specData, "GL", "gl", glTruncPreceedData);

----------------------------------
-- Write include files for the new headers.
for i, output in ipairs(glOutputs) do
	local outVersion = output[2];
	local numOutVersion = tonumber(outVersion);
	local includeList = {typeHeaderName, extHeaderName};
	
	for i, version in ipairs(listOfCoreVersions) do
		local numVersion = tonumber(version);
		if(numVersion > numOutVersion) then
			break;
		end
		
		local coreName = GetCoreInclBasename(version);
		if(newGlOutputs[coreName][4]) then
			includeList[#includeList + 1] = coreName;
		end
		
		if(not output[3]) then
			for i, removalVersion in ipairs(removalVersions) do
				local baseName = GetCoreInclBasename(version, removalVersion)
				if(newGlOutputs[baseName][4]) then
					includeList[#includeList + 1] = baseName;
				end
			end
		else
			for i, removalVersion in ipairs(removalVersions) do
				if(tonumber(removalVersion) > numOutVersion) then
					--Has been removed from core, but not this version.
					local baseName = GetCoreInclBasename(version, removalVersion)
					if(newGlOutputs[baseName][4]) then
						includeList[#includeList + 1] = baseName;
					end
				end
			end
		end
	end

	MakeInclVersionFile(output[1], includeList);
end



local function GetVersionProfIterator()
	local currIx = 1;
	
	return function()
		if(currIx > #glOutputs) then return nil, nil; end;
		
		local currValue = glOutputs[currIx];
		currIx = currIx + 1;
		local profile = nil;
		
		if(currValue[3]) then profile = "core"; else profile = "compatibility"; end;
		
		return currValue[2], profile;
	end
end

--Write the internal headers.
local baseData = {
	enums = {"VERSION", "EXTENSIONS", "NUM_EXTENSIONS", "CONTEXT_PROFILE_MASK", "CONTEXT_CORE_PROFILE_BIT", "CONTEXT_COMPATIBILITY_PROFILE_BIT", "TRUE", "FALSE"},
	
	funcs = {"GetString", "GetStringi", "GetIntegerv"},

	bFuncsAreCore = true,
	
	enumPrefix = "GL",
	
	preceedData = glPreceedData,
};

MakeMainHeaderFile("gll_gl_ext", specData, "gl", GetVersionProfIterator(), baseData);

--MakeCoreHeaderFile("gll_gl_core", specData, "gl");

--Write the internal source files.

local platformDef = dofile(GetDataFilePath() .. "stdPlatformDef.lua");

MakeMainSourceFile("gll_gl_ext", specData, "GL", "gl", GetVersionProfIterator(), glPreceedData,
	baseData, nil);

--MakeCoreSourceFile("gll_gl_core", specData, "gl", platformDef);

---------------------------
--Create WGL files.
local wglSpecData = LoadLuaSpec(specFileLoc .. "wglspec.lua");

local wglPreceedData = {
	dofile(GetDataFilePath() .. "wglPreceed.lua"),
	dofile(GetDataFilePath() .. "wglHeaderFunc.lua"),
	dofile(GetDataFilePath() .. "glDefStr.lua"),
}

local wglbaseData = {
	enums = {},
	funcs = {"GetExtensionsStringARB"},
	bFuncsAreCore = false,
	enumPrefix = "WGL",
	preceedData = wglPreceedData
};


MakeExtHeaderFile("wgl_exts", wglSpecData, "WGL", "wgl", nil, false, wglPreceedData);

MakeMainHeaderFile("wgll_ext", wglSpecData, "wgl", nil, wglbaseData);

MakeMainSourceFile("wgll_ext", wglSpecData, "WGL", "wgl", nil, wglPreceedData,
	wglbaseData, nil);
	
	
---------------------------
--Create GLX files.
local glxSpecData = LoadLuaSpec(specFileLoc .. "glxspec.lua");

local glxPreceedData = {
	dofile(GetDataFilePath() .. "glxPreceed.lua"),
	dofile(GetDataFilePath() .. "glxHeaderFunc.lua"),
	dofile(GetDataFilePath() .. "glDefStr.lua"),
}

MakeExtHeaderFile("glx_exts", glxSpecData, "GLX", "glX", nil, false, glxPreceedData);

MakeMainHeaderFile("glxl_ext", glxSpecData, "glX", nil, glxbaseData);

MakeMainSourceFile("glxl_ext", glxSpecData, "GLX", "glX", nil, glxPreceedData,
	glxbaseData, nil);
	
	
	
	
	
	
	
