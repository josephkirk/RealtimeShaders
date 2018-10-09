//*****************************************************************************
//voxelizeFragmentParallel.vert************************************************
//*****************************************************************************

#version 420

// IN (from OpenGL)
layout(location = 0) in vec3 in_vertexPos;
layout(location = 1) in vec3 in_vertexNormal;
layout(location = 2) in vec2 in_texCoord;

// IN (uniform)
uniform ivec3 volumeDim;

out block
{
	vec3 vertexPos;
	vec3 vertexNormal;
	vec2 texCoord;
} Out;

out gl_PerVertex
{
	vec4 gl_Position;
};

uniform mat4 modelMatrix;

void main()
{
	vec4 vertexPos   = modelMatrix * vec4(in_vertexPos, 1.0);
	vertexPos.xyz   *= volumeDim;
	Out.vertexPos    = vertexPos.xyz;
	Out.vertexNormal = in_vertexNormal;
	Out.texCoord     = in_texCoord;
	gl_Position      = vertexPos;
}
