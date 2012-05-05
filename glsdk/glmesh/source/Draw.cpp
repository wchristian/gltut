//Copyright (C) 2011 by Jason L. McKesson
//This file is licensed by the MIT License.



#include <string.h>
#include <sstream>
#include <glload/gl_all.hpp>
#include <glload/gll.hpp>

#include "glmesh/Draw.h"
#include "glmesh/VertexFormat.h"
#include "glmesh/StreamBuffer.h"

namespace glmesh
{
	MismatchDrawTypeException::MismatchDrawTypeException( int eRequiredType,
		const std::string &realType )
	{
		std::ostringstream temp;
		temp << "You provided the type \"" << realType << "\", for an attribute of type \"" << eRequiredType
			<< "\"" << std::endl;
		message = temp.str();
	}

	TooFewVerticesSentException::TooFewVerticesSentException( int numProvided, size_t numStated )
	{
		std::ostringstream temp;
		temp << "You said you were giving " << numStated << " vertices, but instead you gave "
			<< numProvided << std::endl;
		message = temp.str();
	}

	VertexCountPrimMismatchException::VertexCountPrimMismatchException( const std::string &primName,
		const std::string &primReqs, size_t vertexCount )
	{
		std::ostringstream temp;
		temp << "Primitive " << primName << " has the following restriction on the vertex count:\n\t"
			<< primReqs << "\nYou provided " << vertexCount << " vertices, which violates this requirement."
			<< std::endl;
		message = temp.str();
	}

	namespace
	{
		void ThrowIfNoQuads(const char *quadTypename)
		{
			if(glload::IsVersionGEQ(3, 2))
			{
				GLint iProfileMask = 0;
				gl::GetIntegerv(gl::GL_CONTEXT_PROFILE_MASK, &iProfileMask);
				if(iProfileMask & gl::GL_CONTEXT_CORE_PROFILE_BIT)
					throw PrimitiveTypeUnsupportedException(quadTypename);
			}
			else if(glload::IsVersionGEQ(3, 1))
			{
				if(!glext_ARB_compatibility)
					throw PrimitiveTypeUnsupportedException(quadTypename);
			}
		}

		GLenum ValidatePrimitive(GLenum primType, size_t vertexCount)
		{
			if(vertexCount == 0)
				throw VertexCountPrimMismatchException("Any",
				"Must be greater than 0.", vertexCount);;

			switch(primType)
			{
			case gl::GL_TRIANGLES:
				if(vertexCount % 3 != 0)
				{
					throw VertexCountPrimMismatchException("GL_TRIANGLES",
						"Must be divisible by 3.", vertexCount);
				}
				break;
			case gl::GL_TRIANGLE_STRIP:
			case gl::GL_TRIANGLE_FAN:
				if(vertexCount < 3)
				{
					throw VertexCountPrimMismatchException("GL_TRIANGLES_STRIP/FAN",
						"Must be >= 3.", vertexCount);
				}
				break;
			case gl::GL_POINTS:
				break;
			case gl::GL_LINES:
				if(vertexCount % 2 != 0)
				{
					throw VertexCountPrimMismatchException("GL_LINES",
						"Must be divisible by 2.", vertexCount);
				}
				break;
			case gl::GL_LINE_LOOP:
			case gl::GL_LINE_STRIP:
				if(vertexCount < 2)
				{
					throw VertexCountPrimMismatchException("GL_LINE_LOOP/STRIP",
						"Must be >= 2.", vertexCount);
				}
				break;
			case gl::GL_QUADS:
				ThrowIfNoQuads("GL_QUADS");
				if(vertexCount % 4)
				{
					throw VertexCountPrimMismatchException("GL_QUADS",
						"Must be divisible by 4.", vertexCount);
				}
				break;
			case gl::GL_QUAD_STRIP:
				ThrowIfNoQuads("GL_QUAD_STRIP");
				if(vertexCount < 4)
				{
					throw VertexCountPrimMismatchException("GL_QUAD_STRIP",
						"Must be >= 4.", vertexCount);
				}
				if(vertexCount % 2 != 0)
				{
					throw VertexCountPrimMismatchException("GL_QUAD_STRIP",
						"Must be divisible by 2.", vertexCount);
				}
				break;
			default:
				throw PrimitiveTypeUnsupportedException("Unknown primitive.");
			}

			return primType;
		}
	}

	Draw::Draw( GLenum primType, size_t vertexCount, const VertexFormat &fmt, StreamBuffer &buffer )
		: m_primType(ValidatePrimitive(primType, vertexCount))
		, m_vertexCount(vertexCount)
		, m_fmt(fmt)
		, m_map(buffer, vertexCount * fmt.GetVertexByteSize(), true)
		, m_buffer(buffer)
		, m_bufferOffset(buffer.GetBufferPosition())
		, m_currAttrib(0)
		, m_verticesRemaining((int)vertexCount)
		, m_tempBuffer(fmt.GetVertexByteSize())
	{
	}

	Draw::~Draw()
	{
		InternalRender();
	}

	namespace
	{
		enum InternalRenderErrorCodes
		{
			RENDER_SUCCESS,
			NOT_ENOUGH_VERTICES,
			UNMAP_FAILED_OR_PREV_DRAWN,
		};
	}

	bool Draw::Render()
	{
		switch(InternalRender())
		{
		case RENDER_SUCCESS:
			return true;
		case NOT_ENOUGH_VERTICES:
			throw TooFewVerticesSentException(m_vertexCount - m_verticesRemaining, m_vertexCount);
		case UNMAP_FAILED_OR_PREV_DRAWN:
			return false;
		}

		return false;
	}

	void Draw::ProcessAttrib( const void *pData, size_t bytesPerComponent )
	{
		if(m_verticesRemaining == 0)
			throw TooManyVerticesSentException();

		size_t numComponents = m_fmt.GetAttribDesc(m_currAttrib).GetNumComponents();

		memcpy(GetPtrForAttrib(), pData, bytesPerComponent * numComponents);

		m_currAttrib++;
		if(m_currAttrib >= m_fmt.GetNumAttribs())
		{
			memcpy(GetOutputPtrForVertex(), &m_tempBuffer[0], m_fmt.GetVertexByteSize());
			m_currAttrib = 0;
			m_verticesRemaining--;
		}
	}

	void * Draw::GetPtrForAttrib()
	{
		size_t offset = m_fmt.GetAttribByteOffset(m_currAttrib);
		GLubyte *pData = (&m_tempBuffer[0]);
		return (pData + offset);
	}

	void * Draw::GetOutputPtrForVertex()
	{
		GLubyte *pData = static_cast<GLubyte*>(m_map.GetPtr());
		return (pData + (m_fmt.GetVertexByteSize() * (m_vertexCount - m_verticesRemaining)));
	}

	int Draw::InternalRender()
	{
		if(m_verticesRemaining != 0)
			return NOT_ENOUGH_VERTICES;

		if(!m_map.Release())
			return UNMAP_FAILED_OR_PREV_DRAWN;

		if(m_buffer.GetVao())
			gl::BindVertexArray(m_buffer.GetVao());
		gl::BindBuffer(gl::GL_ARRAY_BUFFER, m_buffer.GetBuffer());

		{
			VertexFormat::Enable bind(m_fmt, m_bufferOffset);

			gl::DrawArrays(m_primType, 0, m_vertexCount);
		}

		gl::BindBuffer(gl::GL_ARRAY_BUFFER, 0);
		if(m_buffer.GetVao())
			gl::BindVertexArray(0);

		return RENDER_SUCCESS;
	}
}
