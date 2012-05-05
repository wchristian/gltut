local thisDirectory = os.getcwd();

local LinkFuncs =
{
	glload = function()
		includedirs "glload/include"
		libdirs "glload/lib"

		configuration "Debug"
			links {"glloadD"}

		configuration "Release"
			links {"glload"}
	end,
	glimage = function()
		includedirs "glimg/include"
		libdirs "glimg/lib"

		configuration "Debug"
			links {"glimgD"}

		configuration "Release"
			links {"glimg"}
	end,
	glutil = function()
		includedirs "glutil/include"
		libdirs "glutil/lib"

		configuration "Debug"
			links {"glutilD"}

		configuration "Release"
			links {"glutil"}
	end,
	glmesh = function()
		includedirs "glmesh/include"
		libdirs "glmesh/lib"

		configuration "Debug"
			links {"glmeshD"}

		configuration "Release"
			links {"glmesh"}
	end,
	glm = function()
		includedirs "glm"
	end,
	freeglut = function()
		includedirs "freeglut/include"
		libdirs "freeglut/lib"
		defines {"FREEGLUT_STATIC", "_LIB", "FREEGLUT_LIB_PRAGMAS=0"}
		
		configuration "Debug"
			links {"freeglutD"}
		
		configuration "Release"
			links {"freeglut"}
	end,
	glfw = function()
		includedirs "glfw/include"
		libdirs "glfw/library"
		
		configuration "Debug"
			links {"glfwD"}
		
		configuration "Release"
			links {"glfw"}
	end,
}

local function ProcTable(tbl)
	for i, lib in ipairs(tbl) do
		if(type(lib) == "string") then
			if(not LinkFuncs[lib]) then
				print("Bad library named ", lib);
			else
				local prevDir = os.getcwd()
				os.chdir(thisDirectory)
				configuration {}

				LinkFuncs[lib]()
				
				configuration {}
				os.chdir(prevDir)
			end
		elseif(type(lib) == "table") then
			ProcTable(lib);
		end
	end
end

function UseLibs(...)
	local libList = {...}
	ProcTable(libList)
end
