//Copyright (C) 2011 by Jason L. McKesson
//This file is licensed by the MIT License.



#include <glload/gl_all.hpp>
#include <glload/gll.hpp>
#include "glutil/Shader.h"

namespace glutil
{
	namespace
	{
		void ThrowIfShaderCompileFailed(GLuint shader)
		{
			GLint status;
			gl::GetShaderiv(shader, gl::GL_COMPILE_STATUS, &status);
			if (status == gl::GL_FALSE)
				throw CompileLinkException(shader);
		}

		void ThrowIfProgramLinkFailed(GLuint program)
		{
			GLint status;
			gl::GetProgramiv (program, gl::GL_LINK_STATUS, &status);
			if (status == gl::GL_FALSE)
			{
				throw CompileLinkException(program, true);
			}
		}

		void ThrowIfNotSeparable()
		{
			if(!glload::IsVersionGEQ(4, 1))
			{
				if(!glext_ARB_separate_shader_objects)
					throw SeparateShaderNotSupported();
			}
		}
	}

	CompileLinkException::CompileLinkException( GLuint shader )
	{
		GLint infoLogLength;
		gl::GetShaderiv(shader, gl::GL_INFO_LOG_LENGTH, &infoLogLength);

		GLchar *strInfoLog = new GLchar[infoLogLength + 1];
		gl::GetShaderInfoLog(shader, infoLogLength, NULL, strInfoLog);

		message.assign(strInfoLog, infoLogLength);

		delete[] strInfoLog;

		gl::DeleteShader(shader);
	}

	CompileLinkException::CompileLinkException( GLuint program, bool )
	{
		GLint infoLogLength;
		gl::GetProgramiv(program, gl::GL_INFO_LOG_LENGTH, &infoLogLength);

		GLchar *strInfoLog = new GLchar[infoLogLength + 1];
		gl::GetProgramInfoLog(program, infoLogLength, NULL, strInfoLog);

		message.assign(strInfoLog, infoLogLength);

		delete[] strInfoLog;

		gl::DeleteProgram(program);
	}

	SeparateShaderNotSupported::SeparateShaderNotSupported()
		: ShaderException("Implementation does not support shader object separation.")
	{}

	GLuint CompileShader( GLenum shaderType, const char *shaderText )
	{
		GLuint shader = gl::CreateShader(shaderType);
		gl::ShaderSource(shader, 1, static_cast<const GLchar **>(&shaderText), NULL);
		gl::CompileShader(shader);

		ThrowIfShaderCompileFailed(shader);

		return shader;
	}

	GLuint CompileShader( GLenum shaderType, const std::string &shaderText )
	{
		GLuint shader = gl::CreateShader(shaderType);
		GLint textLength = (GLint)shaderText.size();
		const GLchar *pText = static_cast<const GLchar *>(shaderText.c_str());
		gl::ShaderSource(shader, 1, &pText, &textLength);
		gl::CompileShader(shader);

		ThrowIfShaderCompileFailed(shader);

		return shader;
	}

	GLuint CompileShader( GLenum shaderType, const char **shaderList, size_t numStrings )
	{
		GLuint shader = gl::CreateShader(shaderType);
		gl::ShaderSource(shader, numStrings, static_cast<const GLchar **>(shaderList), NULL);
		gl::CompileShader(shader);

		ThrowIfShaderCompileFailed(shader);

		return shader;
	}

	GLuint CompileShader( GLenum shaderType, const std::vector<std::string> &shaderList )
	{
		std::vector<const GLchar *> stringList;
		std::vector<GLint> stringLengths;
		stringList.reserve(shaderList.size());
		stringLengths.reserve(shaderList.size());

		for(size_t loop = 0; loop < shaderList.size(); ++loop)
		{
			stringLengths.push_back((GLint)shaderList[loop].size());
			stringList.push_back(static_cast<const GLchar *>(shaderList[loop].c_str()));
		}

		GLuint shader = gl::CreateShader(shaderType);
		gl::ShaderSource(shader, shaderList.size(), &stringList[0], &stringLengths[0]);
		gl::CompileShader(shader);

		ThrowIfShaderCompileFailed(shader);

		return shader;
	}

	GLuint LinkProgram( GLuint shaderOne, GLuint shaderTwo )
	{
		GLuint program = gl::CreateProgram();
		return LinkProgram(program, shaderOne, shaderTwo);
	}

	GLuint LinkProgram( GLuint program, GLuint shaderOne, GLuint shaderTwo )
	{
		gl::AttachShader(program, shaderOne);
		gl::AttachShader(program, shaderTwo);	

		gl::LinkProgram(program);
		ThrowIfProgramLinkFailed(program);

		gl::DetachShader(program, shaderOne);
		gl::DetachShader(program, shaderTwo);	
		return program;
	}

	GLuint LinkProgram( const char *vertexShader, const char *fragmentShader )
	{
		GLuint vertShader = CompileShader(gl::GL_VERTEX_SHADER, vertexShader);
		GLuint fragShader = 0;
		try
		{
			fragShader = CompileShader(gl::GL_FRAGMENT_SHADER, fragmentShader);
		}
		catch(...)
		{
			gl::DeleteShader(vertShader);
			throw;
		}

		try
		{
			GLuint program = LinkProgram(vertShader, fragShader);
			gl::DeleteShader(vertShader);
			gl::DeleteShader(fragShader);
			return program;
		}
		catch(...)
		{
			gl::DeleteShader(vertShader);
			gl::DeleteShader(fragShader);
			throw;
		}
	}

	GLuint LinkProgram( const std::string &vertexShader, const std::string &fragmentShader )
	{
		GLuint vertShader = CompileShader(gl::GL_VERTEX_SHADER, vertexShader);
		GLuint fragShader = 0;
		try
		{
			fragShader = CompileShader(gl::GL_FRAGMENT_SHADER, fragmentShader);
		}
		catch(...)
		{
			gl::DeleteShader(vertShader);
			throw;
		}

		try
		{
			GLuint program = LinkProgram(vertShader, fragShader);
			gl::DeleteShader(vertShader);
			gl::DeleteShader(fragShader);
			return program;
		}
		catch(...)
		{
			gl::DeleteShader(vertShader);
			gl::DeleteShader(fragShader);
			throw;
		}
	}

	GLuint LinkProgram( GLuint program, const char *vertexShader, const char *fragmentShader )
	{
		GLuint vertShader = CompileShader(gl::GL_VERTEX_SHADER, vertexShader);
		GLuint fragShader = 0;
		try
		{
			fragShader = CompileShader(gl::GL_FRAGMENT_SHADER, fragmentShader);
		}
		catch(...)
		{
			gl::DeleteShader(vertShader);
			throw;
		}

		try
		{
			LinkProgram(program, vertShader, fragShader);
			gl::DeleteShader(vertShader);
			gl::DeleteShader(fragShader);
			return program;
		}
		catch(...)
		{
			gl::DeleteShader(vertShader);
			gl::DeleteShader(fragShader);
			throw;
		}
	}

	GLuint LinkProgram( GLuint program, const std::string &vertexShader, const std::string &fragmentShader )
	{
		GLuint vertShader = CompileShader(gl::GL_VERTEX_SHADER, vertexShader);
		GLuint fragShader = 0;
		try
		{
			fragShader = CompileShader(gl::GL_FRAGMENT_SHADER, fragmentShader);
		}
		catch(...)
		{
			gl::DeleteShader(vertShader);
			throw;
		}

		try
		{
			LinkProgram(program, vertShader, fragShader);
			gl::DeleteShader(vertShader);
			gl::DeleteShader(fragShader);
			return program;
		}
		catch(...)
		{
			gl::DeleteShader(vertShader);
			gl::DeleteShader(fragShader);
			throw;
		}
	}

	GLuint LinkProgram( GLuint shader, bool isSeparable )
	{
		if(isSeparable)
			ThrowIfNotSeparable();

		GLuint program = gl::CreateProgram();
		if(isSeparable)
			gl::ProgramParameteri(program, gl::GL_PROGRAM_SEPARABLE, gl::GL_TRUE);

		gl::AttachShader(program, shader);

		gl::LinkProgram(program);
		ThrowIfProgramLinkFailed(program);
		gl::DetachShader(program, shader);
		return program;
	}

	GLuint LinkProgram( const std::vector<GLuint> &shaders, bool isSeparable )
	{
		if(isSeparable)
			ThrowIfNotSeparable();

		GLuint program = gl::CreateProgram();
		if(isSeparable)
			gl::ProgramParameteri(program, gl::GL_PROGRAM_SEPARABLE, gl::GL_TRUE);

		return LinkProgram(program, shaders);
	}

	GLuint LinkProgram( GLuint program, const std::vector<GLuint> &shaders )
	{
		for(size_t loop = 0; loop < shaders.size(); ++loop)
			gl::AttachShader(program, shaders[loop]);

		gl::LinkProgram(program);
		ThrowIfProgramLinkFailed(program);

		for(size_t loop = 0; loop < shaders.size(); ++loop)
			gl::DetachShader(program, shaders[loop]);

		return program;
	}

	GLuint MakeSeparableProgram( GLenum shaderType, const char *shaderText )
	{
		ThrowIfNotSeparable();

		GLuint program = gl::CreateShaderProgramv(shaderType, 1, &shaderText);
		ThrowIfProgramLinkFailed(program);
		return program;
	}

	GLuint MakeSeparableProgram( GLenum shaderType, const std::string &shaderText )
	{
		return MakeSeparableProgram(shaderType, shaderText.c_str());
	}

	GLuint MakeSeparableProgram( GLenum shaderType, const char **shaderList, size_t numStrings )
	{
		ThrowIfNotSeparable();

		GLuint program = gl::CreateShaderProgramv(shaderType, numStrings,
			static_cast<const GLchar **>(shaderList));
		ThrowIfProgramLinkFailed(program);
		return program;
	}

	GLuint MakeSeparableProgram( GLenum shaderType, const std::vector<std::string> &shaderList )
	{
		std::vector<const char *> stringList;
		stringList.reserve(shaderList.size());

		for(size_t loop = 0; loop < shaderList.size(); ++loop)
			stringList.push_back(shaderList[loop].c_str());

		return MakeSeparableProgram(shaderType, &stringList[0], shaderList.size());
	}
}
