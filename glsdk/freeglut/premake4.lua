solution "freeglut"
	configurations {"Debug", "Release"}
	defines {"_CRT_SECURE_NO_WARNINGS", "_SCL_SECURE_NO_WARNINGS"}

dofile("freeglut.lua");	

local dirs = os.matchdirs("progs/demos/*")
for i, dir in ipairs(dirs) do
	local baseDir = path.getname(dir);
	
	if(baseDir ~= "bin" and baseDir ~= "obj") then
		project(baseDir)
			kind "ConsoleApp"
			language "c"
			includedirs {"include"}
			targetdir(dir)
			objdir(dir .. "/obj")
			files {dir .. "/*.c"};
			
			defines {"FREEGLUT_STATIC", "_LIB", "FREEGLUT_LIB_PRAGMAS=0"}
			links {"freeglut"}
			
			configuration "windows"
				defines "WIN32"
				links {"glu32", "opengl32", "gdi32", "winmm", "user32"}
				
			configuration "linux"
			    links {"GL"}
				
			configuration "Debug"
				targetsuffix "D"
				defines "_DEBUG"
				flags "Symbols"

			configuration "Release"
				defines "NDEBUG"
				flags {"OptimizeSpeed", "NoFramePointer", "ExtraWarnings", "NoEditAndContinue"};
	end
end


