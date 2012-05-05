//Copyright (C) 2011 by Jason L. McKesson
//This file is licensed by the MIT License.



#include <stdio.h>
#include <string>
#include <glload/gl_all.hpp>
#include "glutil/Debug.h"

namespace glutil
{
	namespace
	{
		GLDEBUGPROCARB oldProc = NULL;

		std::string GetErrorSource(GLenum source)
		{
			switch(source)
			{
			case gl::GL_DEBUG_SOURCE_API_ARB: return "API";
			case gl::GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB: return "Window System";
			case gl::GL_DEBUG_SOURCE_SHADER_COMPILER_ARB: return "Shader Compiler";
			case gl::GL_DEBUG_SOURCE_THIRD_PARTY_ARB: return "Third Party";
			case gl::GL_DEBUG_SOURCE_APPLICATION_ARB: return "Application";
			case gl::GL_DEBUG_SOURCE_OTHER_ARB: return "Other";
			default: return "WTF?";
			}
		}

		std::string GetErrorType(GLenum type)
		{
			switch(type)
			{
			case gl::GL_DEBUG_TYPE_ERROR_ARB: return "Error";
			case gl::GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB: return "Deprecated Functionality";
			case gl::GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB: return "Undefined Behavior";
			case gl::GL_DEBUG_TYPE_PORTABILITY_ARB: return "Portability";
			case gl::GL_DEBUG_TYPE_PERFORMANCE_ARB: return "Performance";
			case gl::GL_DEBUG_TYPE_OTHER_ARB: return "Other";
			default: return "WTF?";
			}
		}

		std::string GetErrorSeverity(GLenum severity)
		{
			switch(severity)
			{
			case gl::GL_DEBUG_SEVERITY_HIGH_ARB: return "High";
			case gl::GL_DEBUG_SEVERITY_MEDIUM_ARB: return "Medium";
			case gl::GL_DEBUG_SEVERITY_LOW_ARB: return "Low";
			default: return "WTF?";
			}
		}

		void APIENTRY DebugFuncStdOut(GLenum source, GLenum type, GLuint id, GLenum severity,
			GLsizei length, const GLchar* message, GLvoid* userParam)
		{
			if(oldProc)
				oldProc(source, type, id, severity, length, message, userParam);

			std::string srcName = GetErrorSource(source);
			std::string errorType = GetErrorType(type);
			std::string typeSeverity = GetErrorSeverity(severity);

			printf("************************\n%s from %s,\t%s priority\nMessage: %s\n",
				errorType.c_str(), srcName.c_str(), typeSeverity.c_str(), message);
		}

		void APIENTRY DebugFuncStdErr(GLenum source, GLenum type, GLuint id, GLenum severity,
			GLsizei length, const GLchar* message, GLvoid* userParam)
		{
			if(oldProc)
				oldProc(source, type, id, severity, length, message, userParam);

			std::string srcName = GetErrorSource(source);
			std::string errorType = GetErrorType(type);
			std::string typeSeverity = GetErrorSeverity(severity);

			fprintf(stderr, "************************\n%s from %s,\t%s priority\nMessage: %s\n",
				errorType.c_str(), srcName.c_str(), typeSeverity.c_str(), message);
		}
	}

	bool RegisterDebugOutput( OutputLocation eLoc )
	{
		if(!glext_ARB_debug_output)
			return false;

		void *pData = NULL;
		gl::GetPointerv(gl::GL_DEBUG_CALLBACK_FUNCTION_ARB, (void**)(&oldProc));
		if(oldProc)
			gl::GetPointerv(gl::GL_DEBUG_CALLBACK_USER_PARAM_ARB, &pData);

		gl::Enable(gl::GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB);

		switch(eLoc)
		{
		case STD_OUT:
			gl::DebugMessageCallbackARB(DebugFuncStdOut, pData);
			break;
		case STD_ERR:
			gl::DebugMessageCallbackARB(DebugFuncStdErr, pData);
			break;
		}

		return true;
	}
}

