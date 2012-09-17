//-----------------------------------------------------------
// MMDEffect.fx
//
// �ق�Wilfrem�l��MMDX�̃G�t�F�N�g�t�@�C���̃R�s�y
//-----------------------------------------------------------

float4x4 World;
float4x4 View;
float4x4 Projection;

//-----------------------------------------------------------------------------
// �e�N�X�`��
//-----------------------------------------------------------------------------
texture Texture;
uniform const sampler TextureSampler : register(s0) = sampler_state
{
	Texture = (Texture);
	// Linear : �o�C���j�A�t�B���^�B�A���`�G�C���A�X����
	// XNA���ƃf�t�H�Ń~�b�v�}�b�v���g���ă}�b�s���O����񂾂���
	MipFilter = Linear;	// �~�b�v�}�b�v�t�B���^
	MinFilter = Linear;	// �k���t�B���^
	MagFilter = Linear;	// �g��t�B���^
}
//�X�t�B�A�}�b�v�g�p�t���O�B0:���� 1:��Z 2:���Z
uniform const int UseSphere;
texture ShereTexture;
uniform const sampler ShereSampler : register(s1) = sampler_state
{
	Texture = (ShereTexture);
	MipFilter = Linear;	// �~�b�v�}�b�v�t�B���^
	MinFilter = Linear;	// �k���t�B���^
	MagFilter = Linear;	// �g��t�B���^
}
uniform const bool UseToon;
texture ToonTexture;
uniform const sampler ToonSampler : register(s2) = sampler_state
{
	Texture = (ToonTexture);
	MipFilter = Linear;	// �~�b�v�}�b�v�t�B���^
	MinFilter = Linear;	// �k���t�B���^
	MagFilter = Linear;	// �g��t�B���^
}

//-----------------------------------------------------------------------------
// �萔���W�X�^�錾
//-----------------------------------------------------------------------------
// shared�͑���VS�ł�PS�ł��g����ϐ����悭�炢�̈Ӗ�
uniform shared const float3	EyePosition;		// in world space

//-----------------------------------------------------------------------------
// �}�e���A���ݒ�
//-----------------------------------------------------------------------------

uniform const float3	DiffuseColor	: register(c0) = 1;
uniform const float		Alpha			: register(c1) = 1;
uniform const float3	EmissiveColor	: register(c2) = 0;
uniform const float3	SpecularColor	: register(c3) = 1;
uniform const float		SpecularPower	: register(c4) = 16;
uniform const bool		Edge = true;

//-----------------------------------------------------------------------------
// ���C�g�ݒ�
//-----------------------------------------------------------------------------
uniform const float3	LightColor;
uniform const float3	DirLight0Direction;

//-----------------------------------------------------------------------------
// �}�g���b�N�X
//-----------------------------------------------------------------------------
uniform const float4x4 World;				// �I�u�W�F�N�g�̃��[���h���W
uniform shared const float4x4 View;			// �r���[�̃g�����X�t�H�[��
uniform shared const float4x4 Projection;	// �v���W�F�N�V�����̃g�����X�t�H�[��

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
// ���C�e�B���O�̌v�Z
// E: �����x�N�g��
// N: ���[���h���W�n�ł̒P�ʖ@���x�N�g��
//-----------------------------------------------------------------------------

ColorPair ConputeLights(float3 E, float3 N)
{
	ColorPair colorPair;

	c.Diffuse = LightColor;
	colorPair.Specular = 0;

	// Directional Light 0
	float3 L = normalize(-DirLight0Direction);
	float3 H = normalize(E + L);
	// Blin�̃��f���Ń��C�e�B���O�W���i�@���E�n�[�t�x�N�g���E���C�g��������Z�o����閾�Ï��Ȃǁj���v�Z
	// x, w �͂��ꂼ��1�By��diffuse, z��specular�ɑ΂���W��
	float2 ret = lit(dot(N, L), dot(N, H),  SpecularPower).yz;
	colorPair.Specular += LightColor * ret.y;

	// MMD�ł�Emissive�𑫂��Ă���saturate����̂������炵��
	colorPair.Diffuse *= DiffuseColor;
	colorPair.Diffuse += EmissiveColor;
	colorPair.Diffuse = saturate(result.Diffuse);
	colorPair.Specular *= SpecularColor;
	
	//�g�D�[���e�N�X�`���p�̃T���v���ʒu���v�Z
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
	
	//�g�D�[���e�N�X�`���擾�ʒu���R�s�[
	vout.ToonTexCoord=lightResult.ToonTex;
	//�X�t�B�A�v�Z
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
// �V�F�[�_�[
//-----------------------------------------------------------------------------

int ShaderIndex = 0; // �ǂ̃V�F�[�_���g����

VertexShader VSArray[2] =
{
	compile vs_2_0 VSBasicNm(),		// �@������
//	compile vs_2_0 VSBasicNmTx(),	// �@�� + �e�N�X�`��
}

VertexShader PSArray[2] =
{
	compile ps_2_0 PSBasicNm(),		// �@������
//	compile ps_2_0 PSBasicNmTx(),	// �@�� + �e�N�X�`��
}

technique Technique1
{
    pass MMDEffect
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}
