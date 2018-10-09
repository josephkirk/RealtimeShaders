//*****************************************************************************
//voxelizeFragmentParallel.frag************************************************
//*****************************************************************************

#version 420

#define L     0.7071067811865475244008443621048490392848359376884740
#define L_SQR 0.5

#define THIN 0 	//6-separating
#define FAT  1	//26-separating
#define THICKNESS THIN

layout(binding = 0, std140) uniform Material
{
	vec4  diffuse;
	vec4  ambient;
	vec4  specular;
	vec4  emissive;
	float shininess;
	int   texCount;
} material;

in block
{
	vec3 vertexPos;
	vec3 vertexNormal;
	vec2 texCoord;
} In;

uniform sampler2D      diffuseTex;
uniform sampler2D     specularTex;
uniform sampler2D transmissiveTex;

//OUT
layout(location = 0) out vec4 FragColor;

// IN voxels extents snapped to voxel grid (post swizzle)
flat in ivec3 minVoxIndex;
flat in ivec3 maxVoxIndex;

// IN 2D projected edge normals
flat in vec2 n_e0_xy;
flat in vec2 n_e1_xy;
flat in vec2 n_e2_xy;
flat in vec2 n_e0_yz;
flat in vec2 n_e1_yz;
flat in vec2 n_e2_yz;
flat in vec2 n_e0_zx;
flat in vec2 n_e1_zx;
flat in vec2 n_e2_zx;

// IN
flat in float d_e0_xy;
flat in float d_e1_xy;
flat in float d_e2_xy;
flat in float d_e0_yz;
flat in float d_e1_yz;
flat in float d_e2_yz;
flat in float d_e0_zx;
flat in float d_e1_zx;
flat in float d_e2_zx;

// IN pre-calculated triangle intersection stuff
flat in vec3  nProj;
#if THICKNESS == THIN
flat in float dTriThin;
#elif THICKNESS == FAT
flat in float dTriFatMin;
flat in float dTriFatMax;
#endif
flat in float nzInv;

flat in int Z;

//Voxel output
layout(r32ui, binding = 0) uniform uimage3D Voxels;

void writeVoxels(ivec3 coord, uint val, vec3 color)
{
	//modify as necessary for attributes/storage type
	imageStore(Voxels, coord, uvec4(val));
}

void main()
{
	if(any(greaterThan(In.vertexPos, maxVoxIndex)) || any(lessThan(In.vertexPos, minVoxIndex)))
	{
		discard;
		return;
	}

	ivec3 p = ivec3(In.vertexPos);	//voxel coordinate (swizzled)
	int   zMin,      zMax;			//voxel Z-range
	float zMinInt,   zMaxInt;		//voxel Z-intersection min/max
	float zMinFloor, zMaxCeil;		//voxel Z-intersection floor/ceil

	float dd_e0_xy = d_e0_xy + dot(n_e0_xy, p.xy);
	float dd_e1_xy = d_e1_xy + dot(n_e1_xy, p.xy);
	float dd_e2_xy = d_e2_xy + dot(n_e2_xy, p.xy);

	bool xy_overlap = (dd_e0_xy >= 0) && (dd_e1_xy >= 0) && (dd_e2_xy >= 0);

	if(xy_overlap)	//figure 17 line 15, figure 18 line 14
	{
		float dot_n_p = dot(nProj.xy, p.xy);
#if THICKNESS == THIN
		zMinInt = (-dot_n_p + dTriThin) * nzInv;
		zMaxInt = zMinInt;
#elif THICKNESS == FAT
		zMinInt = (-dot_n_p + dTriFatMin) * nzInv;
		zMaxInt = (-dot_n_p + dTriFatMax) * nzInv;
#endif
		zMinFloor = floor(zMinInt);
		zMaxCeil  =  ceil(zMaxInt);

		zMin = int(zMinFloor) - int(zMinFloor == zMinInt);
		zMax = int(zMaxCeil ) + int(zMaxCeil  == zMaxInt);

		zMin = max(minVoxIndex.z, zMin);	//clamp to bounding box max Z
		zMax = min(maxVoxIndex.z, zMax);	//clamp to bounding box min Z

		for(p.z = zMin; p.z < zMax; p.z++)	//figure 17/18 line 18
		{
			float dd_e0_yz = d_e0_yz + dot(n_e0_yz, p.yz);
			float dd_e1_yz = d_e1_yz + dot(n_e1_yz, p.yz);
			float dd_e2_yz = d_e2_yz + dot(n_e2_yz, p.yz);
	
			float dd_e0_zx = d_e0_zx + dot(n_e0_zx, p.zx);
			float dd_e1_zx = d_e1_zx + dot(n_e1_zx, p.zx);
			float dd_e2_zx = d_e2_zx + dot(n_e2_zx, p.zx);
	
			bool yz_overlap = (dd_e0_yz >= 0) && (dd_e1_yz >= 0) && (dd_e2_yz >= 0);
			bool zx_overlap = (dd_e0_zx >= 0) && (dd_e1_zx >= 0) && (dd_e2_zx >= 0);

			if(yz_overlap && zx_overlap)	//figure 17/18 line 19
			{
				//Calculate color and other attributes here if applicable
				vec3 color = (material.texCount == 0) ? material.diffuse.xyz : texture2D(diffuseTex, In.texCoord).xyz;
				
				ivec3 origCoord = (Z == 0) ? p.yzx : (Z == 1) ? p.zxy : p.xyz;	//this actually slightly outperforms unswizzle

				writeVoxels(origCoord, 1, color);	//figure 17/18 line 20
			}
		}
		//z-loop
	}
	//xy-overlap test

	discard;
}