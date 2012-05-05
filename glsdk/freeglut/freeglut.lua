
if(_ACTION == "gmake") then
    os.execute("sh ./configure");
end

project "freeglut"
	kind "StaticLib"
	language "c"
	includedirs {"include"}
	targetdir "lib"
	files {"src/*.c"};
	
	defines {"FREEGLUT_STATIC", "_LIB", "FREEGLUT_LIB_PRAGMAS=0"}
	
	configuration "windows"
		defines "WIN32"
		
	configuration "gmake"
        defines {"HAVE_CONFIG_H", }
        includedirs {"."}
		
	configuration "Debug"
		targetsuffix "D"
		defines "_DEBUG"
		flags "Symbols"

	configuration "Release"
		defines "NDEBUG"
		flags {"OptimizeSpeed", "NoFramePointer", "ExtraWarnings", "NoEditAndContinue"};
