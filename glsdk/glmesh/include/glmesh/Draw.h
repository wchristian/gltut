/** Copyright (C) 2011 by Jason L. McKesson **/
/** This file is licensed by the MIT License. **/



#ifndef DRAW_MESH_H
#define DRAW_MESH_H

/**
\file
\brief Declares the Draw class and its helper types. Include an OpenGL header before including this one.
**/

#include <vector>
#include <string>
#include <exception>
#include <glm/glm.hpp>
#include <glm/gtc/half_float.hpp>
#include "VertexFormat.h"
#include "StreamBuffer.h"

namespace glmesh
{
	///\addtogroup module_glmesh_exceptions
	///@{

	///Base class for all Draw specific exceptions.
	class DrawException : public std::exception
	{
	public:
		virtual ~DrawException() throw() {}

		virtual const char *what() const throw() {return message.c_str();}

	protected:
		std::string message;
	};

	///Thrown when the type the Draw::Attrib functions are used with does not match the type of the attribute as defined by the VertexFormat.
	class MismatchDrawTypeException : public DrawException
	{
	public:
		MismatchDrawTypeException(int eRequiredType, const std::string &realType);
	};

	///Thrown when drawing with Draw and you did not provide as many vertices as promised.
	class TooFewVerticesSentException : public DrawException
	{
	public:
		TooFewVerticesSentException(int numProvided, size_t numStated);
	};

	///Thrown when calling Attrib and you are writing more vertices than you promised.
	class TooManyVerticesSentException : public DrawException
	{
	public:
		TooManyVerticesSentException()
		{
			message = "You provided more attribute data than you said you would.";
		}
	};

	///Thrown when creating a Draw with a primitive type that the current OpenGL implementation does not support.
	class PrimitiveTypeUnsupportedException : public DrawException
	{
	public:
		PrimitiveTypeUnsupportedException(const std::string &primTypename)
		{
			message = "The primitive type \"" + primTypename + "\" is not supported by OpenGL.";
		}
	};

	///Thrown when the primitive type and vertex count cannot be used together.
	class VertexCountPrimMismatchException : public DrawException
	{
	public:
		VertexCountPrimMismatchException(const std::string &primName, const std::string &primReqs,
			size_t vertexCount);
	};

	///@}

	///\addtogroup module_glmesh_draw
	///@{

	/**
	\brief RAII-style class for immediate-mode type rendering through a VertexFormat and StreamBuffer.

	The constructor of this class is given an OpenGL primitive type and the number of vertices to use.
	You must then call one of the Attrib member functions for each vertex and for each attribute
	in the VertexFormat. The order of attributes within a vertex corresponds to the order of
	attributes in the VertexFormat.

	The Attrib specialization must match the type of the attribute from the VertexFormat \em exactly.
	The number of components however does not have to match.

	Successfully constructing an object of this type will affect the following OpenGL state (note: none
	of this state will be touched in the event of an exception):

	\li The current GL_ARRAY_BUFFER binding.
	\li If VAOs are available, the current VAO will be affected. The current VAO after this object is
	destroyed will be VAO 0. The VAO used to render will be the one stored in the StreamBuffer.
	\li If VAOs are not available, the current attribute array state will be modified as
	VertexFormat::Enable does. Note that you should make sure that all attributes are disabled
	*before* rendering with this immediate mode. Otherwise, badness can result.

	\note Do \em not attempt to change buffer binding state while an instance of this class is constructed.
	Also, do not attempt to create two of these objects at the same time.

	\todo The 1.0 for the fourth value doesn't work right with normalized values.

	\note This class cannot be copied.
	**/
	class Draw
	{
	public:
		/**
		\brief Creates a non-copyable object for drawing.

		\param primType The OpenGL primitive type to render.
		\param vertexCount The number of vertices you will provide. This must work with \a primType
		or an exception is thrown.
		\param fmt The format of the attributes in each vertex. Taken by reference; do not destroy
		this before this object is destroyed.
		\param buffer The streaming buffer that will be used to store the vertex data. Taken by
		reference; do not destroy this before this object is destroyed.

		\throw PrimitiveTypeUnsupportedException If \a primType is not supported on the OpenGL implementation.
		\throw VertexCountPrimMismatchException If \a vertexCount does not match \a primType's requirements.
		\throw StreamBuffer::Map Anything that this class throws, except for NotEnoughRemainingStorageForMapException.

		In the event of any exceptions, nothing is mapped and the StreamBuffer is not touched.
		**/
		Draw(GLenum primType, size_t vertexCount, const VertexFormat &fmt, StreamBuffer &buffer);

		/**
		\brief Draws, if the object has not been drawn previously with a call to Render().
		
		Unlike Render, this does not throw exceptions, since throwing exceptions in a destructor is bad.
		By letting this fall off the stack without an explicit render, you are effectively saying
		that you don't care to error check.

		Therefore, if not enough vertices have been provided, then nothing will be rendered.
		**/
		~Draw();

		/**
		\brief Draws the vertex data provided, if the object has not previously been drawn.

		You can only call this after calling the Attrib functions enough times to provide a full set
		of attribute data for all vertices, as specified by \a vertexCount in the constructor.

		\return true if the vertex data was rendered. False if Render has already been called or if the
		unmapping of the buffer failed. In both cases, nothing is rendered.

		\throw TooFewVerticesSentException If you have not provided all of the vertices promised by the vertex count.
		**/
		bool Render();

		/**
		\name Attribute Setting Functions
		
		The Attrib functions set the value of the current attribute.

		The Attrib series of functions are all templates based on certain types that the Draw class
		accepts.
		
		If you attempt to use the wrong type for the current attribute, an exception will be thrown. The
		types must match \em exactly; there is no narrowing or expansion of shorts into bytes or ints.
		Nor is there conversion from signed to unsigned types.

		Though the types must match, the number of components do not have to exactly match. Per
		OpenGL standard conventions, if you provide more components for an attribute than a vertex format
		allows, the extras will be ignored. If you provide fewer, then rest will be filled in with zeros,
		except for fourth (if applicable), which will be 1.

		If you get an unresolved external error for some form of Draw::Attrib, it is because you are
		not using the correct type. The valid types are, in the order defined in VertexDataType:

		\li \c glm::thalf
		\li \c GLfloat
		\li \c GLdouble
		\li \c GLbyte
		\li \c GLubyte
		\li \c GLshort
		\li \c GLushort
		\li \c GLint
		\li \c GLuint

		There are vector versions of these functions. They will work with glm's vector types, but
		only for certain ones. The 3 floating-point types (glm::hvec, glm::vec, glm::dvec) will work.
		And if you specifically use glm::detail::vec#<type>, then you can use vector types directly.
		Otherwise, you should probably stick to the overloads that take a number of scalar values.

		\throw TooManyVerticesSentException If more vertices have been sent than were originally specified.
		\throw MismatchDrawTypeException If the type you are using does not exactly match the type
		specified by the VertexFormat for this attribute.
		**/

		///@{

		template<typename BaseType>
		void Attrib(BaseType x)
		{
			Attrib<BaseType>(glm::detail::tvec4<BaseType>(x, BaseType(0), BaseType(0), BaseType(1)));
		}

		template<typename BaseType>
		void Attrib(BaseType x, BaseType y)
		{
			Attrib<BaseType>(glm::detail::tvec4<BaseType>(x, y, BaseType(0), BaseType(1)));
		}

		template<typename BaseType>
		void Attrib(const glm::detail::tvec2<BaseType> &val)
		{
			Attrib<BaseType>(glm::detail::tvec4<BaseType>(val, BaseType(0), BaseType(1)));
		}

		template<typename BaseType>
		void Attrib(BaseType x, BaseType y, BaseType z)
		{
			Attrib<BaseType>(glm::detail::tvec4<BaseType>(x, y, z, BaseType(1)));
		}

		template<typename BaseType>
		void Attrib(const glm::detail::tvec3<BaseType> &val)
		{
			Attrib<BaseType>(glm::detail::tvec4<BaseType>(val, BaseType(1)));
		}

		template<typename BaseType>
		void Attrib(BaseType x, BaseType y, BaseType z, BaseType w)
		{
			Attrib<BaseType>(glm::detail::tvec4<BaseType>(x, y, z, w));
		}

		template<typename BaseType>
		void Attrib(const glm::detail::tvec4<BaseType> &val);

		///@}



	private:
		GLenum m_primType;
		size_t m_vertexCount;
		const VertexFormat &m_fmt;
		StreamBuffer::Map m_map;
		StreamBuffer &m_buffer;

		const size_t m_bufferOffset;
		size_t m_currAttrib;
		int m_verticesRemaining;
		std::vector<GLubyte> m_tempBuffer;
		

		//No copying.
		Draw(const Draw &);
		Draw& operator=(const Draw&);

		void ProcessAttrib(const void *pData, size_t bytesPerComponent);
		void *GetPtrForAttrib();
		void *GetOutputPtrForVertex();

		template<typename BaseType>
		void VerifyType();

		int InternalRender();
	};

	template<>
	inline void Draw::VerifyType<glm::half>()
	{
		VertexDataType eType = m_fmt.GetAttribDesc(m_currAttrib).GetVertexDataType();
		if(eType != VDT_HALF_FLOAT)
			throw MismatchDrawTypeException(eType, "half");
	}

	template<>
	inline void Draw::VerifyType<GLfloat>()
	{
		VertexDataType eType = m_fmt.GetAttribDesc(m_currAttrib).GetVertexDataType();
		if(eType != VDT_SINGLE_FLOAT)
			throw MismatchDrawTypeException(eType, "float");
	}

	template<>
	inline void Draw::VerifyType<GLdouble>()
	{
		VertexDataType eType = m_fmt.GetAttribDesc(m_currAttrib).GetVertexDataType();
		if(eType != VDT_DOUBLE_FLOAT)
			throw MismatchDrawTypeException(eType, "double");
	}

	template<>
	inline void Draw::VerifyType<GLbyte>()
	{
		VertexDataType eType = m_fmt.GetAttribDesc(m_currAttrib).GetVertexDataType();
		if(eType != VDT_SIGN_BYTE)
			throw MismatchDrawTypeException(eType, "signed byte");
	}

	template<>
	inline void Draw::VerifyType<GLubyte>()
	{
		VertexDataType eType = m_fmt.GetAttribDesc(m_currAttrib).GetVertexDataType();
		if(eType != VDT_UNSIGN_BYTE)
			throw MismatchDrawTypeException(eType, "unsigned byte");
	}

	template<>
	inline void Draw::VerifyType<GLshort>()
	{
		VertexDataType eType = m_fmt.GetAttribDesc(m_currAttrib).GetVertexDataType();
		if(eType != VDT_SIGN_SHORT)
			throw MismatchDrawTypeException(eType, "signed short");
	}

	template<>
	inline void Draw::VerifyType<GLushort>()
	{
		VertexDataType eType = m_fmt.GetAttribDesc(m_currAttrib).GetVertexDataType();
		if(eType != VDT_UNSIGN_SHORT)
			throw MismatchDrawTypeException(eType, "unsigned short");
	}

	template<>
	inline void Draw::VerifyType<GLint>()
	{
		VertexDataType eType = m_fmt.GetAttribDesc(m_currAttrib).GetVertexDataType();
		if(eType != VDT_SIGN_INT)
			throw MismatchDrawTypeException(eType, "signed int");
	}

	template<>
	inline void Draw::VerifyType<GLuint>()
	{
		VertexDataType eType = m_fmt.GetAttribDesc(m_currAttrib).GetVertexDataType();
		if(eType != VDT_UNSIGN_INT)
			throw MismatchDrawTypeException(eType, "unsigned int");
	}

	template<>
	inline void Draw::Attrib<glm::half>(const glm::detail::tvec4<glm::half> &val)
	{
		VerifyType<glm::half>();
		glm::half theData[4];
		theData[0] = val[0];
		theData[1] = val[1];
		theData[2] = val[2];
		theData[3] = val[3];
		ProcessAttrib(theData, sizeof(glm::half));
	}

	template<>
	inline void Draw::Attrib<GLfloat>(const glm::detail::tvec4<GLfloat> &val)
	{
		VerifyType<GLfloat>();
		GLfloat theData[4];
		theData[0] = val[0];
		theData[1] = val[1];
		theData[2] = val[2];
		theData[3] = val[3];
		ProcessAttrib(theData, sizeof(GLfloat));
	}

	template<>
	inline void Draw::Attrib<GLdouble>(const glm::detail::tvec4<GLdouble> &val)
	{
		VerifyType<GLdouble>();
		GLdouble theData[4];
		theData[0] = val[0];
		theData[1] = val[1];
		theData[2] = val[2];
		theData[3] = val[3];
		ProcessAttrib(theData, sizeof(GLdouble));
	}

	template<>
	inline void Draw::Attrib<GLbyte>(const glm::detail::tvec4<GLbyte> &val)
	{
		VerifyType<GLbyte>();
		GLbyte theData[4];
		theData[0] = val[0];
		theData[1] = val[1];
		theData[2] = val[2];
		theData[3] = val[3];
		ProcessAttrib(theData, sizeof(GLbyte));
	}

	template<>
	inline void Draw::Attrib<GLubyte>(const glm::detail::tvec4<GLubyte> &val)
	{
		VerifyType<GLubyte>();
		GLubyte theData[4];
		theData[0] = val[0];
		theData[1] = val[1];
		theData[2] = val[2];
		theData[3] = val[3];
		ProcessAttrib(theData, sizeof(GLubyte));
	}

	template<>
	inline void Draw::Attrib<GLshort>(const glm::detail::tvec4<GLshort> &val)
	{
		VerifyType<GLshort>();
		GLshort theData[4];
		theData[0] = val[0];
		theData[1] = val[1];
		theData[2] = val[2];
		theData[3] = val[3];
		ProcessAttrib(theData, sizeof(GLshort));
	}

	template<>
	inline void Draw::Attrib<GLushort>(const glm::detail::tvec4<GLushort> &val)
	{
		VerifyType<GLushort>();
		GLushort theData[4];
		theData[0] = val[0];
		theData[1] = val[1];
		theData[2] = val[2];
		theData[3] = val[3];
		ProcessAttrib(theData, sizeof(GLushort));
	}

	template<>
	inline void Draw::Attrib<GLint>(const glm::detail::tvec4<GLint> &val)
	{
		VerifyType<GLint>();
		GLint theData[4];
		theData[0] = val[0];
		theData[1] = val[1];
		theData[2] = val[2];
		theData[3] = val[3];
		ProcessAttrib(theData, sizeof(GLint));
	}

	template<>
	inline void Draw::Attrib<GLuint>(const glm::detail::tvec4<GLuint> &val)
	{
		VerifyType<GLuint>();
		GLuint theData[4];
		theData[0] = val[0];
		theData[1] = val[1];
		theData[2] = val[2];
		theData[3] = val[3];
		ProcessAttrib(theData, sizeof(GLuint));
	}


	///@}
}
#endif //DRAW_MESH_H
