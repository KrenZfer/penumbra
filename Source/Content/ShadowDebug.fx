﻿cbuffer cbPerFrame
{
	float4 Color;
};

cbuffer cbPerObject
{
	float4x4 WorldViewProjection;
};

struct VertexIn
{
	float3 occluderCoord_radius : SV_POSITION0;
	float2 segmentA_soften : TEXCOORD0;
	float2 segmentB : TEXCOORD1;
};

struct VertexOut
{
	float4 position : SV_POSITION;
	float4 penumbra : TEXCOORD1;
	float clipValue : TEXCOORD2;
};

float2x2 penumbraMatrix(float2 basisX, float2 basisY) {
	float2x2 m = float2x2(basisX, basisY);
	// Find inverse of m. https://www.mathsisfun.com/algebra/matrix-inverse.html
	return float2x2(m._m11, -m._m01, -m._m10, m._m00) / determinant(m);
}

VertexOut VS(VertexIn vin)
{
	float2 occluderCoord = vin.occluderCoord_radius.xy;	
	// Ensure radius never reaches 0.
	float radius = max(1e-5, vin.occluderCoord_radius.z);	

	float2 segmentA = vin.segmentA_soften.xy;
	float2 segmentB = vin.segmentB;

	// Find radius offsets 90deg left and right from light source relative to vertex.
	float2 lightOffsetA = float2(-radius, radius)*normalize(segmentA).yx; // 90 CCW.
	float2 lightOffsetB = float2(radius, -radius)*normalize(segmentB).yx; // 90 CW.

	// From each edge, project a quad. 4 vertices per edge.
	float2 position = lerp(segmentA, segmentB, occluderCoord.x);
	float2 projectionOffset = lerp(lightOffsetA, lightOffsetB, occluderCoord.x);
	float4 projected = float4(position - projectionOffset*occluderCoord.y, 0.0, 1.0 - occluderCoord.y);

	// Transform to ndc.
	float4 clipPosition = mul(projected, WorldViewProjection);
	
	float2 penumbraA = mul(projected.xy - segmentA*projected.w, penumbraMatrix(lightOffsetA, segmentA));
	float2 penumbraB = mul(projected.xy - segmentB*projected.w, penumbraMatrix(lightOffsetB, segmentB));

	float2 clipNormal = normalize(segmentB - segmentA).yx*float2(-1.0, 1.0);
	// 90 CCW. ClipValue > 0 means the projection is pointing towards us => no shadow should be generated.
	float clipValue = dot(clipNormal, projected.xy - projected.w*position);
	
	VertexOut vout;
	vout.position = clipPosition;
	vout.penumbra = float4(penumbraA, penumbraB);
	vout.clipValue = clipValue;

	return vout;
}

float4 PS(VertexOut pin) : SV_TARGET
{
	clip(-pin.clipValue);
	return Color;
}

technique Main
{
	pass P0
	{
		VertexShader = compile vs_4_0_level_9_1 VS();
		PixelShader = compile ps_4_0_level_9_1 PS();
	}
}