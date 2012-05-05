/** Copyright (C) 2011 by Jason L. McKesson **/
/** This file is licensed by the MIT License. **/



#ifndef GLSDK_MESH_QUADRICS_H
#define GLSDK_MESH_QUADRICS_H

/**
\file
\brief Defines mesh generators for various quadrics and curved surfaces.
**/

#include "GenDescriptors.h"

namespace glmesh
{
	class Mesh;

	namespace gen
	{
		///\addtogroup module_glmesh_mesh_generator
		///@{

		/**
		\brief Creates a unit sphere at the origin.

		A unit sphere is a sphere of radius 1, so it extends from [-1, 1] in all three axes.
		
		**/
		Mesh *UnitSphere(int numHorizSlices, int numVertSlices);

		///@}
	}
}



#endif //GLSDK_MESH_QUADRICS_H
