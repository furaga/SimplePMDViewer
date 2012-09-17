//-----------------------------------------------------------
// MMDEffect.fx
//
// ほぼWilfrem様のMMDXのエフェクトファイルのコピペ
//-----------------------------------------------------------

float4x4 World;
float4x4 View;
float4x4 Projection;

//-----------------------------------------------------------------------------
// テクスチャ
//-----------------------------------------------------------------------------
texture Texture;
uniform const sampler TextureSampler : register(s0) = sampler_state
{
	Texture = (Texture);
	// Linear : バイリニアフィルタ。アンチエイリアスする
	// XNAだとデフォでミップマップを使ってマッピングするんだって
	MipFilter = Linear;	// ミップマップフィルタ
	MinFilter = Linear;	// 縮小フィルタ
	MagFilter = Linear;	// 拡大フィルタ
}
//スフィアマップ使用フラグ。0:無し 1:乗算 2:加算
uniform const int UseSphere;
texture ShereTexture;
uniform const sampler ShereSampler : register(s1) = sampler_state
{
	Texture = (ShereTexture);
	MipFilter = Linear;	// ミップマップフィルタ
	MinFilter = Linear;	// 縮小フィルタ
	MagFilter = Linear;	// 拡大フィルタ
}
uniform const bool UseToon;
texture ToonTexture;
uniform const sampler ToonSampler : register(s2) = sampler_state
{
	Texture = (ToonTexture);
	MipFilter = Linear;	// ミップマップフィルタ
	MinFilter = Linear;	// 縮小フィルタ
	MagFilter = Linear;	// 拡大フィルタ
}

//-----------------------------------------------------------------------------
// 定数レジスタ宣言
//-----------------------------------------------------------------------------
// sharedは多分VSでもPSでも使える変数だよくらいの意味
uniform shared const float3	EyePosition;		// in world space

//-----------------------------------------------------------------------------
// マテリアル設定
//-----------------------------------------------------------------------------

uniform const float3	DiffuseColor	: register(c0) = 1;
uniform const float		Alpha			: register(c1) = 1;
uniform const float3	EmissiveColor	: register(c2) = 0;
uniform const float3	SpecularColor	: register(c3) = 1;
uniform const float		SpecularPower	: register(c4) = 16;
uniform const bool		Edge = true;

//-----------------------------------------------------------------------------
// ライト設定
//-----------------------------------------------------------------------------
uniform const float3	LightColor;
uniform const float3	DirLight0Direction;

//-----------------------------------------------------------------------------
// マトリックス
//-----------------------------------------------------------------------------
uniform const float4x4 World;				// オブジェクトのワールド座標
uniform shared const float4x4 View;			// ビューのトランスフォーム
uniform shared const float4x4 Projection;	// プロジェクションのトランスフォーム

//-----------------------------------------------------------------------------
// Structure definitions
//-----------------------------------------------------------------------------

struct ColorPair
{
	float3 Diffuse;
	float3 Specular;
	float2 ToonTex;
};

struct CommonVSOutput
{
	float4 Pos_ws;
	float4 Pos_ps;
	float4 Diffuse;
	float3 Specular;
	float2 ToonTexCoord;
	float2 SphereCoord;
};

//-----------------------------------------------------------------------------
// Vertex shader inputs
//-----------------------------------------------------------------------------

struct VSInputNm
{
	float4 Position	: POSITION;
	float3 Normal	: NORMAL;
};

struct VSInputNmTx
{
	float4 Position	: POSITION;
	float3 Normal	: NORMAL;
	float2 TexCoord	: TEXCOORD0;
};


//-----------------------------------------------------------------------------
// Vertex shader outputs
//-----------------------------------------------------------------------------

struct VertexLightingVSOutput
{
	float4 PositionPS	: POSITION;		// Position in projection space
	float4 Diffuse		: COLOR0;
	float4 Specular		: COLOR1;		// Specular.rgb and fog factor
	float2 SphereCoord	: TEXCOORD1;
	float2 ToonTexCoord	: TEXCOORD2;
};

struct VertexLightingVSOutputTx
{
	float4 PositionPS	: POSITION;		// Position in projection space
	float4 Diffuse		: COLOR0;
	float4 Specular		: COLOR1;
	float2 TexCoord		: TEXCOORD0;
	float2 SphereCoord	: TEXCOORD1;
	float2 ToonTexCoord	: TEXCOORD2;
};

struct EdgeVSOutput
{
	float4 PositionPS	: POSITION;
	float4 Color		: COLOR0;
};

//-----------------------------------------------------------------------------
// Pixel shader inputs
//-----------------------------------------------------------------------------

struct VertexLightingPSInput
{
	float4 Diffuse		: COLOR0;
	float4 Specular		: COLOR1;
	float2 SphereCoord	: TEXCOORD1;
	float2 ToonTexCoord	: TEXCOORD2;
};

struct VertexLightingPSInputTx
{
	float4 Diffuse		: COLOR0;
	float4 Specular		: COLOR1;
	float2 TexCoord		: TEXCOORD0;
	float2 SphereCoord	: TEXCOORD1;
	float2 ToonTexCoord	: TEXCOORD2;
};

//-----------------------------------------------------------------------------
// ライティングの計算
// E: 視線ベクトル
// N: ワールド座標系での単位法線ベクトル
//-----------------------------------------------------------------------------

ColorPair ConputeLights(float3 E, float3 N)
{
	ColorPair colorPair;

	c.Diffuse = LightColor;
	colorPair.Specular = 0;

	// Directional Light 0
	float3 L = normalize(-DirLight0Direction);
	float3 H = normalize(E + L);
	// Blinのモデルでライティング係数（法線・ハーフベクトル・ライト方向から算出される明暗情報など）を計算
	// x, w はそれぞれ1。yはdiffuse, zはspecularに対する係数
	float2 ret = lit(dot(N, L), dot(N, H),  SpecularPower).yz;
	colorPair.Specular += LightColor * ret.y;

	// MMDではEmissiveを足してからsaturateするのが正解らしい
	colorPair.Diffuse *= DiffuseColor;
	colorPair.Diffuse += EmissiveColor;
	colorPair.Diffuse = saturate(result.Diffuse);
	colorPair.Specular *= SpecularColor;
	
	//トゥーンテクスチャ用のサンプル位置を計算
	colorPair.ToonTex.x = clamp(0.5f - dot(normalize(N),normalize(E)) * 0.5f, 0, 1);
	colorPair.ToonTex.y = clamp(0.5f - dot(normalize(N),normalize(L)) * 0.5f, 0, 1);
	
	return colorPair;
}

CommonVSOutput ComputeCommonVSOutputWithLighting(float4 position, float3 normal)
{
	CommonVSOutput vout;
	
	float4 pos_ws = mul(position, World);
	float4 pos_vs = mul(pos_ws, View);
	float4 pos_ps = mul(pos_vs, Projection);
	vout.Pos_ws = pos_ws;
	vout.Pos_ps = pos_ps;
	
	float3 N = normalize(mul(normal, World));
	float3 posToEye = EyePosition - pos_ws;
	float3 E = normalize(posToEye);
	ColorPair lightResult = ComputeLights(E, N);
	
	vout.Diffuse	= float4(lightResult.Diffuse.rgb, Alpha);
	vout.Specular	= lightResult.Specular;
	
	//トゥーンテクスチャ取得位置をコピー
	vout.ToonTexCoord=lightResult.ToonTex;
	//スフィア計算
	vout.SphereCoord=float2(normal.x/2+0.5,normal.y/2+0.5);
	
	return vout;
}


//-----------------------------------------------------------------------------
// Vertex shaders
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Pixel shaders
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// シェーダー
//-----------------------------------------------------------------------------

int ShaderIndex = 0; // どのシェーダを使うか

VertexShader VSArray[2] =
{
	compile vs_2_0 VSBasicNm(),		// 法線だけ
//	compile vs_2_0 VSBasicNmTx(),	// 法線 + テクスチャ
}

VertexShader PSArray[2] =
{
	compile ps_2_0 PSBasicNm(),		// 法線だけ
//	compile ps_2_0 PSBasicNmTx(),	// 法線 + テクスチャ
}

technique Technique1
{
    pass MMDEffect
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}
