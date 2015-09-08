﻿cbuffer cbPerObject
{
	float4 Color;
	float4x4 World;
};

cbuffer cbPerFrame
{
	float4x4 ViewProjection;
};

struct VertexIn
{
	float2 Position : SV_POSITION0;
};

struct VertexOut
{
	float4 Position : SV_POSITION;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout;

	float4 posW = mul(float4(vin.Position.x, vin.Position.y, 0.0f, 1.0f), World);
	vout.Position = mul(posW, ViewProjection);

	return vout;
}

float4 PS(VertexOut pin) : SV_TARGET
{
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
