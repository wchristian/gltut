
newoption {
	trigger			= "plainc",
	description		= "Set this to build GL Load without C++ support.",
}


project("glload")
	kind "StaticLib"
	includedirs {"include", "source"}
	targetdir "lib"

	if(_OPTIONS["plainc"]) then
		language "c"
	else
		language "c++"
	end

	files {
		"include/glload/gl_*.h",
		"include/glload/gl_*.hpp",
		"include/glload/gll.h",
		"include/glload/gll.hpp",
		"source/gll*.c",
		"source/gll*.cpp",
		"source/gll*.h",
	};
	
	configuration "plainc"
		excludes {
			"source/gll*.cpp",
			"include/glload/gll.hpp",
			"include/glload/gl_*.hpp"
		}
	
	configuration "windows"
		defines {"WIN32"}
		files {"include/glload/wgl_*.h",}
		files {"source/wgll*.c",
			"source/wgll*.cpp",
			"source/wgll*.h",}
	
	configuration "linux"
	    defines {"LOAD_X11"}
		files {"include/glload/glx_*.h"}
		files {"source/glxl*.c",
			"source/glxl*.cpp",
			"source/glxl*.h",}

	configuration "Debug"
		flags "Unicode";
		defines {"DEBUG", "_DEBUG", "MEMORY_DEBUGGING"};
		objdir "Debug";
		flags "Symbols";
		targetname "glloadD";

	configuration "Release"
		defines {"NDEBUG", "RELEASE"};
		flags "Unicode";
		flags {"OptimizeSpeed", "NoFramePointer", "ExtraWarnings", "NoEditAndContinue"};
		objdir "Release";
		targetname "glload"
