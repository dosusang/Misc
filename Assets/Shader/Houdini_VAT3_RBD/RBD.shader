Shader "Unlit/RBD"
{
    Properties
    {
        //        [ToggleUI]_B_autoPlayback("Auto Playback", Float) = 1
        //        _gameTimeAtFirstFrame("Game Time at First Frame", Float) = 0
        //        _displayFrame("Display Frame", Float) = 1
        //        _playbackSpeed("Playback Speed", Float) = 1
        //_houdiniFPS("Houdini FPS", Float) = 60
        [ToggleUI]_B_interpolate("Interframe Interpolation", Float) = 0
        //        [ToggleUI]_B_interpolateCol("Interpolate Color", Float) = 0
        //        [ToggleUI]_B_interpolateSpareCol("Interpolate Spare Color", Float) = 0
        //        [ToggleUI]_B_surfaceNormals("Support Surface Normal Maps", Float) = 1
        //        [ToggleUI]_B_twoSidedNorms("Two Sided Normals", Float) = 0
        //[NoScaleOffset]_posTexture("Position Texture", 2D) = "white" {}
        //         [NoScaleOffset]_posTexture2("Position Texture 2", 2D) = "white" {}
        //[NoScaleOffset]_rotTexture("Rotation Texture", 2D) = "white" {}
        //[NoScaleOffset]_colTexture("Color Texture", 2D) = "white" {}
        //         [NoScaleOffset]_spareColTexture("Spare Color Texture", 2D) = "white" {}
        //         [ToggleUI]_B_pscaleAreInPosA("Piece Scales Are in Position Alpha", Float) = 1
        _globalPscaleMul("Global Piece Scale Multiplier", Float) = 1
        //         [ToggleUI]_B_stretchByVel("Stretch by Velocity", Float) = 0
        //         _stretchByVelAmount("Stretch by Velocity Amount", Float) = 0
        //         [ToggleUI]_B_animateFirstFrame("Animate First Frame", Float) = 0
        //         [Toggle(_B_LOAD_COL_TEX)]_B_LOAD_COL_TEX("Load Color Texture", Float) = 1
        //         [Toggle(_B_SMOOTH_TRAJECTORIES)]_B_SMOOTH_TRAJECTORIES("Smoothly Interpolated Trajectories", Float) = 0
        //         [Toggle(_B_LOAD_NORM_TEX)]_B_LOAD_NORM_TEX("Load Surface Normal Map", Float) = 0
        //         [Toggle(_B_LOAD_POS_TWO_TEX)]_B_LOAD_POS_TWO_TEX("Positions Require Two Textures", Float) = 0
        _frameCount("Frame Count", Float) = 0
        _boundMaxX("Bound Max X", Float) = 0
        _boundMaxY("Bound Max Y", Float) = 0
        _boundMaxZ("Bound Max Z", Float) = 0
        _boundMinX("Bound Min X", Float) = 0
        _boundMinY("Bound Min Y", Float) = 0
        _boundMinZ("Bound Min Z", Float) = 0
        //         [NonModifiableTextureData][Normal][NoScaleOffset]_SampleTexture2D_72ab43ee7e5b4ff3acd5a9fb57f150dc_Texture_1("Texture2D", 2D) = "bump" {}
        //         [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        //         [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        //         [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        //         [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        //         [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}


        _posTexture ("_posTexture", 2D) = "white" {}
        _rotTexture ("_rotTexture", 2D) = "white" {}
        _colTexture ("_colTexture", 2D) = "white" {}

        _houdiniFPS("_houdiniFPS", int) = 24
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        float4 _BaseColor;
        int _frameCount;
        int _houdiniFPS;
        float _B_interpolate;
        float _boundMaxX;
        float _boundMaxY;
        float _boundMaxZ;
        float _boundMinX;
        float _boundMinY;
        float _boundMinZ;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;

                float4 color : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float3 normal : TEXCOORD4;

                float4 color : COLOR;
            };

            sampler2D _BaseMap;
            sampler2D _posTexture;
            sampler2D _rotTexture;
            sampler2D _colTexture;

            float4 DecodeQuaternion(float3 XYZ, int MaxComponent)
            {
                float w = sqrt(1.0 - pow(XYZ.x, 2) - pow(XYZ.y, 2) - pow(XYZ.z, 2));
                float4 q = float4(0, 0, 0, 1);
                switch (MaxComponent)
                {
                case 0:
                    q = float4(XYZ.x, XYZ.y, XYZ.z, w);
                    break;
                case 1:
                    q = float4(w, XYZ.y, XYZ.z, XYZ.x);
                    break;
                case 2:
                    q = float4(XYZ.x, -w, XYZ.z, -XYZ.y);
                    break;
                case 3:
                    q = float4(XYZ.x, XYZ.y, -w, -XYZ.z);
                    break;
                default:
                    q = float4(XYZ.x, XYZ.y, XYZ.z, w);
                    break;
                }
                return q;
            }

            float3 RotateVec(float3 v, float4 q)
            {
                float3 i = q.rgb;
                float r = q.a;
                return v + float3(2, 2, 2) * cross(i, r * v + cross(i, v));
            }

            Varyings UnlitPassVertex(Attributes input)
            {
                Varyings output;

                float3 vRot = 0;
                float4 posOffset = 0;
                float4 rotOffset = 0;

                float activePixelsRatioY = 1 - (-_boundMaxX * 10 - floor(-_boundMaxX * 10));

                float time = _Time.y;
                float uA = _frameCount * frac(time * (_houdiniFPS / (_frameCount - 0.01)));
                float uB = floor(uA + 1);
                float uC = activePixelsRatioY * ((uB - 1) % _frameCount) * (1.0 / _frameCount);

                float V = 1 - (uC + (1 - input.uv1.g) * activePixelsRatioY);
                float V2 = 1 - ((1 - input.uv1.g) * activePixelsRatioY + activePixelsRatioY * (uB % _frameCount) * 1 / _frameCount);

                float3 v = input.positionOS - float3(-input.uv2.r, input.uv3.r, 1 - input.uv3.g);

                if (_B_interpolate < 0.1)
                {
                    posOffset = tex2Dlod(_posTexture, float4(input.uv1.x, V, 0, 0));
                    rotOffset = tex2Dlod(_rotTexture, float4(input.uv1.x, V, 0, 0));
                    rotOffset = DecodeQuaternion(rotOffset.rgb, floor(posOffset.a * 4));
                    vRot = RotateVec(v, rotOffset);
                }
                else
                {
                    float lerpT = frac(uA);
                    float4 posOffsetThisFrame = tex2Dlod(_posTexture, float4(input.uv1.x, V, 0, 0));
                    float4 posOffsetNextFrame = tex2Dlod(_posTexture, float4(input.uv1.x, V2, 0, 0));
                    posOffset = lerp(posOffsetThisFrame, posOffsetNextFrame, lerpT);

                    float4 rotOffsetthisFrame = tex2Dlod(_rotTexture, float4(input.uv1.x, V, 0, 0));
                    float4 rotOffsetNextFrame = tex2Dlod(_rotTexture, float4(input.uv1.x, V2, 0, 0));

                    // 开始插值
                    float4 DecodedRotThisFrame = DecodeQuaternion(rotOffsetthisFrame, floor(posOffsetThisFrame.a * 4));
                    float4 DecodedRotNextFrame = DecodeQuaternion(rotOffsetNextFrame, floor(posOffsetNextFrame.a * 4));

                    float input01A = abs(rotOffsetthisFrame.a);
                    float temp01 = 0.5 * frac(lerpT * input01A);

                    float m1 = sin(TWO_PI * temp01);
                    float m2 = sin(TWO_PI * (0.5 * frac(input01A) - temp01));
                    float4 m3 = DecodedRotNextFrame * sign(rotOffsetthisFrame.a);
                    float4 add1 = m2 * DecodedRotThisFrame + m1 * m3;
                    float4 res = normalize(add1 / sin(0.5 * frac(input01A) * TWO_PI));

                    if (abs(rotOffsetthisFrame.a) > 0.0001)
                    {
                        rotOffset = res;
                    }
                    else
                    {
                        rotOffset = DecodedRotThisFrame;
                    }

                    vRot = RotateVec(v, rotOffset);
                }


                VertexPositionInputs positionInputs = GetVertexPositionInputs(posOffset + vRot);
                output.positionCS = positionInputs.positionCS;

                output.uv0 = input.uv0;
                output.uv1 = input.uv1;
                output.uv2 = input.uv2;
                output.uv3 = input.uv3;
                output.color = input.color;

                output.normal = TransformObjectToWorldNormal(RotateVec(input.normal, rotOffset));
                return output;
            }


            half4 UnlitPassFragment(Varyings input) : SV_Target
            {
                return float4(dot(input.normal, _MainLightPosition.xyz).xxx * tex2D(_colTexture, input.uv1), 1);
            }
            ENDHLSL
        }
    }
}