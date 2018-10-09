//*****************************************************************************
//voxelizeTriangleParallel.geom************************************************
//*****************************************************************************

#version 420

#define THIN 0 
#define FAT  1
#define THICKNESS THIN

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;


in block
{
	vec3 vertexPos;
	vec3 vertexColor;
} In[];


#include "swizzle.glsl"
#include "voxelizeTriPostSwizzle.glsl"


// UNIFORM (from OpenGL)
uniform ivec3 volumeDim;

void main()
{
	vec3 n;
	mat3 unswizzle;
	vec3 v0 = In[0].vertexPos;
	vec3 v1 = In[1].vertexPos;
	vec3 v2 = In[2].vertexPos;
	
	swizzleTri(v0, v1, v2, n, unswizzle);

	vec3 AABBmin = min(min(v0, v1), v2);
	vec3 AABBmax = max(max(v0, v1), v2);

	ivec3 minVoxIndex = ivec3(clamp(floor(AABBmin), ivec3(0), volumeDim));
	ivec3 maxVoxIndex = ivec3(clamp( ceil(AABBmax), ivec3(0), volumeDim));

	voxelizeTriPostSwizzle(v0, v1, v2, n, unswizzle, minVoxIndex, maxVoxIndex);
}
