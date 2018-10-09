//*****************************************************************************
//classifyTriPostSwizzle.glsl**************************************************
//*****************************************************************************

#ifndef CLASSIFIER_GLSL
#define CLASSIFIER_GLSL

#define TRI_AREA_2D  0
#define TRI_AREA_3D  1
#define AABB_AREA_2D 2
#define AABB_VOLUME  3
#define TRI_RATIO    5
#define CLASSIFIER TRI_AREA_2D

#define LARGE 0
#define SMALL 1

float triArea2D(vec2 v0, vec2 v1, vec2 v2)
{
	return abs(v0.x*(v1.y-v2.y) + v1.x*(v2.y-v0.y) + v2.x*(v0.y-v1.y)) * 0.5;
}

float triArea3D(vec3 v0, vec3 v1, vec3 v2)
{
	return dot(cross(v1-v0, v2-v0),cross(v1-v0, v2-v0)) * 0.5;
}

//classify triangle as either LARGE or SMALL acorrding to the selected method
int classifyTriPostSwizzle(vec3 v0, vec3 v1, vec3 v2, vec3 n, float cutoff, const ivec3 volumeDim, out ivec3 minVoxIndex, out ivec3 maxVoxIndex)
{
	vec3 AABBmin = min(min(v0, v1), v2);
	vec3 AABBmax = max(max(v0, v1), v2);

	minVoxIndex = ivec3(clamp(floor(AABBmin), ivec3(0), volumeDim));
	maxVoxIndex = ivec3(clamp( ceil(AABBmax), ivec3(0), volumeDim));

	ivec3 voxExtent = maxVoxIndex - minVoxIndex;

	float val;
#ifdef CLASSIFIER == TRI_AREA_2D
	val = triArea2D(v0.xy, v1.xy, v2.xy);
#elif CLASSIFIER == TRI_AREA_3D
	val = triArea3D(v0, v1, v2);
#elif CLASSIFIER == AABB_AREA_2D
	val = voxExtent.x*voxExtent.y;
#elif CLASSIFIER == AABB_VOLUME_3D
	val = voxExtent.x*voxExtent.y*voxExtent.z;
#elif CLASSIFIER == TRI_RATIO
	vec3 e0 = v1 - v0;
	vec3 e1 = v2 - v1;
	vec3 e2 = v0 - v2;

	//OUTward Facing edge normals
	vec2 n_e0_xy = normalize(vec2(-e0.y, e0.x));
	vec2 n_e1_xy = normalize(vec2(-e1.y, e1.x));
	vec2 n_e2_xy = normalize(vec2(-e2.y, e2.x));

	vec2 v0_prime = v0.xy + L * ( e2.xy / ( dot(e2.xy, n_e0_xy) ) + e0.xy / ( dot(e0.xy, n_e2_xy) ) );
	vec2 v1_prime = v1.xy + L * ( e0.xy / ( dot(e0.xy, n_e1_xy) ) + e1.xy / ( dot(e1.xy, n_e0_xy) ) );
	vec2 v2_prime = v2.xy + L * ( e1.xy / ( dot(e1.xy, n_e2_xy) ) + e2.xy / ( dot(e2.xy, n_e1_xy) ) );

	float triArea       = triArea2D(v0.xy,    v1.xy,    v2.xy   );
	float triArea_prime = triArea2D(v0_prime, v1_prime, v2_prime);

	val = triArea / triArea_prime;
#endif

	return (val >= cutoff) ? LARGE : SMALL;

}

#endif //CLASSIFIER_GLSL
