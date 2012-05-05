/** Copyright (C) 2011 by Jason L. McKesson **/
/** This file is licensed by the MIT License. **/



#ifndef GLSDK_GENERATOR_HELPER_H
#define GLSDK_GENERATOR_HELPER_H

#include <string>
#include "glmesh/Mesh.h"
//Requires having included GL defines.

namespace glmesh
{

	namespace gen
	{
		enum VariantComponents
		{
			VAR_COLOR		= 0x01,
			VAR_NORMAL		= 0x02,
			VAR_TEX_COORD	= 0x04,
		};

		//Generates a name for the given components. Just one of the names that can be used.
		std::string GenerateNameForVariant(const int components);

		void AddVariantToMap(MeshVariantMap &variantMap, GLuint vao, const int components);
	}
}

#endif //GLSDK_GENERATOR_HELPER_H

