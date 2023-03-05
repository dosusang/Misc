Shader "Unlit/TestDepth"
{
    Properties
    {
        _BaseMap ("Example Texture", 2D) = "white" {}
        _BaseColor ("Example Colour", Color) = (0, 0.66, 0.73, 1)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }
        zwrite off
        Blend one zero

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        float4 _BaseColor;
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
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 positionSS : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            Varyings UnlitPassVertex(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.positionSS = ComputeScreenPos(output.positionCS);
                return output;
            }

            half4 UnlitPassFragment(Varyings input) : SV_Target
            {
                float selfDepth = input.positionCS.w;
                float curDepth = LinearEyeDepth(SampleSceneDepth(input.positionSS.xy / input.positionSS.w), _ZBufferParams);

                return  curDepth - selfDepth;
            }
            ENDHLSL
        }
    }
}