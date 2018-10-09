//*****************************************************************************
//voxelizeHybrid.geom**********************************************************
//*****************************************************************************

#version 420

#define L     0.7071067811865475244008443621048490392848359376884740	//sqrt(2)/2
#define L_SQR 0.5

#define THIN 0 
#define FAT  1
#define THICKNESS THIN



layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in block
{
	vec3 vertexPos;
	vec3 vertexColor;
	int  vertexID;
} In[];


#include "swizzle.glsl"
#include "classifyTriPostSwizzle.glsl"
#include "voxelizeTriPostSwizzle.glsl"


layout(binding = 4) uniform uimageBuffer largeIdx;
layout(binding = 5) uniform uimageBuffer largeIndirectElement;

layout(binding = 0) uniform atomic_uint largeTriCount;

uniform ivec3 volumeDim;
uniform float cutoff;

void main()
{
	vec3 n;
	mat3 swizzle;
	vec3 v0 = In[0].vertexPos;
	vec3 v1 = In[1].vertexPos;
	vec3 v2 = In[2].vertexPos;
	
	swizzleTri(v0, v1, v2, n, swizzle);
	
	ivec3 minVoxIndex;
	ivec3 maxVoxIndex;

	int size = classifyTriPostSwizzle(v0, v1, v2, n, cutoff, volumeDim, minVoxIndex, maxVoxIndex);

	if(size == LARGE)
	{
		//Store large triangles
		int index = int(atomicCounterIncrement(largeTriCount));

		imageStore(largeIdx, 3*index+0, uvec4(In[0].vertexID));
		imageStore(largeIdx, 3*index+1, uvec4(In[1].vertexID));
		imageStore(largeIdx, 3*index+2, uvec4(In[2].vertexID));
	}
	else if(size == SMALL)
	{
		//Voxelize small triangles
		voxelizeTriPostSwizzle(v0, v1, v2, n, swizzle, minVoxIndex, maxVoxIndex);
	}

//	memoryBarrier();

	imageStore(largeIndirectElement, 0, uvec4(3*atomicCounter(largeTriCount)));

}
