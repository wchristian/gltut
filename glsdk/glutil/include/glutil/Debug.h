/** Copyright (C) 2011 by Jason L. McKesson **/
/** This file is licensed by the MIT License. **/



#ifndef DEBUG_UTIL_H
#define DEBUG_UTIL_H

/**
\file
\brief Includes a function for attaching to ARB_debug_output and printing error messages automatically.
**/

namespace glutil
{
	///\addtogroup module_glutil_debug
	///@{

	///Possible locations for debug outputs.
	enum OutputLocation
	{
		STD_OUT,	///<Output to standard out.
		STD_ERR,	///<Output to standard error.
	};

	/**
	\brief Registers a function for automatically outputting debug messages.

	This function only works with ARB_debug_output. If this extension is not available, the function
	will return false. If you have registered a function before calling this one, then the registered
	function will pass the function through, including your void* argument.
	
	\param eLoc The destination where errors or other debug messages will be printed.
	\return true if the function was registered.
	**/
	bool RegisterDebugOutput(OutputLocation eLoc);

	///@}
}


#endif //DEBUG_UTIL_H
