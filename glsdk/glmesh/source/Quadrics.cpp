//Copyright (C) 2011 by Jason L. McKesson
//This file is licensed by the MIT License.



#include <vector>
#include <algorithm>
#include <cmath>
#include <glload/gl_all.hpp>
#include <glload/gll.hpp>

#include "glmesh/Mesh.h"
#include "glmesh/Quadrics.h"
#include "GenHelper.h"
#include <glm/glm.hpp>

namespace glmesh
{
	namespace gen
	{
		namespace
		{
			const float g_pi = 3.1415726f;
			const float g_2pi = g_pi * 2.0f;
		}

		Mesh * UnitSphere( int numHorizSlices, int numVertSlices )
		{
			//The term "ring" refers to horizontal slices.
			//The term "segment" refers to vertical slices.

			//////////////////////////////////////////////////////////////////////////
			// Generate the vertex attribute data.
			numHorizSlices = std::max(numHorizSlices, 1);
			numVertSlices = std::max(numVertSlices, 3);

			//+2 to horizontal is for the top and bottom points, which are replicated due to texcoords.
			size_t numRingVerts = numHorizSlices + 2;
			//+1 to vertical is for doubling up on the initial point, again due to texcoords.
			size_t numSegVerts = numVertSlices + 1;
			size_t attribCount = numSegVerts * numRingVerts;

			std::vector<glm::vec3> positions;
			std::vector<glm::vec3> normals;
			std::vector<glm::vec2> texCoords;

			positions.reserve(attribCount);
			normals.reserve(attribCount);
			texCoords.reserve(attribCount);

			float deltaSegTexCoord = 1.0f / numSegVerts;
			float deltaRingTexCoord = 1.0f / numRingVerts;

			for(int segment = 0; segment < numVertSlices; ++segment)
			{
				positions.push_back(glm::vec3(0.0f, 1.0f, 0.0f));
				normals.push_back(glm::vec3(0.0f, 1.0f, 0.0f));
				texCoords.push_back(glm::vec2(deltaSegTexCoord * segment, 1.0f));
			}

			positions.push_back(glm::vec3(0.0f, 1.0f, 0.0f));
			normals.push_back(glm::vec3(0.0f, 1.0f, 0.0f));
			texCoords.push_back(glm::vec2(1.0f, 0.0f));

			float radThetaDelta = g_pi / (numHorizSlices + 1);
			float radRhoDelta = g_2pi / numVertSlices;

			for(int ring = 0; ring < numHorizSlices; ++ring)
			{
				float radTheta = radThetaDelta * (ring + 1);
				float sinTheta = std::sin(radTheta);
				float cosTheta = std::cos(radTheta);

				float ringTexCoord = 1.0f - ((ring + 1) * deltaRingTexCoord);

				for(int segment = 0; segment < numVertSlices; ++segment)
				{
					float radRho = radRhoDelta * segment;
					float sinRho = std::sin(-radRho);
					float cosRho = std::cos(-radRho);

					glm::vec3 currPos(sinTheta * cosRho, cosTheta, sinTheta * sinRho);
					positions.push_back(currPos);
					normals.push_back(currPos);
					texCoords.push_back(glm::vec2(deltaSegTexCoord * segment, ringTexCoord));
				}

				positions.push_back(glm::vec3(sinTheta, cosTheta, 0.0f));
				normals.push_back(glm::vec3(sinTheta, cosTheta, 0.0f));
				texCoords.push_back(glm::vec2(1.0f, ringTexCoord));
			}

			for(int segment = 0; segment < numVertSlices; ++segment)
			{
				positions.push_back(glm::vec3(0.0f, -1.0f, 0.0f));
				normals.push_back(glm::vec3(0.0f, -1.0f, 0.0f));
				texCoords.push_back(glm::vec2(deltaSegTexCoord * segment, 0.0f));
			}

			positions.push_back(glm::vec3(0.0f, 1.0f, 0.0f));
			normals.push_back(glm::vec3(0.0f, 1.0f, 0.0f));
			texCoords.push_back(glm::vec2(1.0f, 0.0f));

			//////////////////////////////////////////////////////////////////////////
			//Generate the index data.
			//Restart index.
			GLuint restartIndex = positions.size();

			size_t stripSize = ((2 * numVertSlices) + 2);
			//One strip for each ring vertex list, minus 1.
			size_t numStrips = (numRingVerts - 1);

			size_t numIndices = numStrips * stripSize;
			//Add one index between each strip for primitive restarting.
			numIndices += (numStrips - 1);

			std::vector<GLuint> indices;
			indices.reserve(numIndices);

			for(size_t strip = 0; strip < numStrips; ++strip)
			{
				GLuint topRingIndex = (strip * numSegVerts);
				GLuint botRingIndex = ((strip + 1) * numSegVerts);

				for(size_t segment = 0; segment < numSegVerts; ++segment)
				{
					indices.push_back(topRingIndex + segment);
					indices.push_back(botRingIndex + segment);
				}

				if(indices.size() != numIndices)
					indices.push_back(restartIndex);
			}

			//////////////////////////////////////////////////////////////////////////
			//Build the buffers.
			size_t vertexBufferSize = 0;

			vertexBufferSize += positions.size() * (sizeof(GLshort) * 4);
			vertexBufferSize += normals.size() * (sizeof(GLshort) * 4);
			vertexBufferSize += texCoords.size() * (sizeof(GLshort) * 2);

			std::vector<GLubyte> data(vertexBufferSize);

			GLshort *pCurrPos = (GLshort*)&data[0];
			for(size_t vert = 0; vert < positions.size(); ++vert)
			{
				pCurrPos[0] = GLshort(positions[vert].x * 32767);
				pCurrPos[1] = GLshort(positions[vert].y * 32767);
				pCurrPos[2] = GLshort(positions[vert].z * 32767);

				pCurrPos[4] = GLshort(normals[vert].x * 32767);
				pCurrPos[5] = GLshort(normals[vert].y * 32767);
				pCurrPos[6] = GLshort(normals[vert].z * 32767);

				GLushort *pTexCorrdLoc = (GLushort*)&pCurrPos[8];

				pTexCorrdLoc[0] = GLushort(texCoords[vert].x * 65535);
				pTexCorrdLoc[1] = GLushort(texCoords[vert].y * 65535);

				pCurrPos += 10;
			}

			pCurrPos = (GLshort*)&data[0];

			std::vector<GLuint> buffers(2);

			gl::GenBuffers(2, &buffers[0]);
			gl::BindBuffer(gl::GL_ARRAY_BUFFER, buffers[0]);
			gl::BufferData(gl::GL_ARRAY_BUFFER, data.size(), &data[0], gl::GL_STATIC_DRAW);

			//vertex data done. Now build the index buffer.
			gl::BindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
			gl::BufferData(gl::GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(GLuint),
				&indices[0], gl::GL_STATIC_DRAW);
			gl::BindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, 0);

			//Create VAOs.
			MeshVariantMap variantMap;

			gl::BindBuffer(gl::GL_ARRAY_BUFFER, buffers[0]);

			GLuint currVao = 0;

			gl::GenVertexArrays(1, &currVao);
			gl::BindVertexArray(currVao);
			gl::BindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
			gl::EnableVertexAttribArray(0);
			gl::VertexAttribPointer(0, 3, gl::GL_SHORT, gl::GL_TRUE, 10 * sizeof(GLshort), (void*)0);
			AddVariantToMap(variantMap, currVao, 0);

			gl::GenVertexArrays(1, &currVao);
			gl::BindVertexArray(currVao);
			gl::BindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
			gl::EnableVertexAttribArray(0);
			gl::VertexAttribPointer(0, 3, gl::GL_SHORT, gl::GL_TRUE, 10 * sizeof(GLshort), (void*)0);
			gl::EnableVertexAttribArray(2);
			gl::VertexAttribPointer(2, 3, gl::GL_SHORT, gl::GL_TRUE, 10 * sizeof(GLshort),
				(void*)(4 * sizeof(GLshort)));
			AddVariantToMap(variantMap, currVao, VAR_NORMAL);

			gl::GenVertexArrays(1, &currVao);
			gl::BindVertexArray(currVao);
			gl::BindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
			gl::EnableVertexAttribArray(0);
			gl::VertexAttribPointer(0, 3, gl::GL_SHORT, gl::GL_TRUE, 10 * sizeof(GLshort), (void*)0);
			gl::EnableVertexAttribArray(5);
			gl::VertexAttribPointer(5, 3, gl::GL_UNSIGNED_SHORT, gl::GL_TRUE, 10 * sizeof(GLshort),
				(void*)(8 * sizeof(GLushort)));
			AddVariantToMap(variantMap, currVao, VAR_TEX_COORD);

			gl::GenVertexArrays(1, &currVao);
			gl::BindVertexArray(currVao);
			gl::BindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
			gl::EnableVertexAttribArray(0);
			gl::VertexAttribPointer(0, 3, gl::GL_SHORT, gl::GL_TRUE, 10 * sizeof(GLshort), (void*)0);
			gl::EnableVertexAttribArray(2);
			gl::VertexAttribPointer(2, 3, gl::GL_SHORT, gl::GL_TRUE, 10 * sizeof(GLshort),
				(void*)(4 * sizeof(GLshort)));
			gl::EnableVertexAttribArray(5);
			gl::VertexAttribPointer(5, 3, gl::GL_UNSIGNED_SHORT, gl::GL_TRUE, 10 * sizeof(GLshort),
				(void*)(8 * sizeof(GLushort)));
			AddVariantToMap(variantMap, currVao, VAR_TEX_COORD | VAR_NORMAL);

			gl::BindVertexArray(0);
			gl::BindBuffer(gl::GL_ARRAY_BUFFER, 0);

			//////////////////////////////////////////////////////////////////////////
			//Create rendering commands.
			RenderCmdList renderCmds;
			if(glload::IsVersionGEQ(3, 1))
			{
				//Has primitive restart. Therefore, can draw two fans as one.
				renderCmds.PrimitiveRestartIndex(restartIndex);
				renderCmds.DrawElements(gl::GL_TRIANGLE_STRIP, numIndices, gl::GL_UNSIGNED_INT, 0);
				renderCmds.PrimitiveRestartIndex();
			}
			else
			{
				//No restart. Must draw each strip one after the other.
				for(size_t strip = 0; strip < numStrips; ++strip)
				{
					GLuint stripStart = strip * (stripSize + 1);

					renderCmds.DrawElements(gl::GL_TRIANGLE_STRIP, stripSize, gl::GL_UNSIGNED_INT,
						stripStart * sizeof(GLuint));
				}
			}

			GLuint mainVao = variantMap["lit-tex"];

			Mesh *pRet = new Mesh(buffers, mainVao, renderCmds, variantMap);
			return pRet;
		}
	}
}

