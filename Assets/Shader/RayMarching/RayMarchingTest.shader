Shader "Unlit/RayMarchingTest"
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
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        float4 _BaseColor;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "Unlit"
            zwrite off
            blend one one

            HLSLPROGRAM
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            float GetShadow(float3 positionWS)
            {
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                float shadow = MainLightRealtimeShadow(shadowCoord);
                return shadow;
            }
            
            Varyings UnlitPassVertex(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                return output;
            }

            // 重建世界空间位置。
            half3 GetWorldPos(half2 uv)
            {
                #if UNITY_REVERSED_Z
                real depth = SampleSceneDepth(uv);
                #else
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

                float3 worldPos = ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
                return worldPos;
            }


            half4 UnlitPassFragment(Varyings input) : SV_Target
            {
                half4 color = 0;
                half2 screenUV = input.positionCS.xy / _ScaledScreenParams.xy;
                half3 endWorldPos = GetWorldPos(screenUV);
                half3 curPos = _WorldSpaceCameraPos;
                half maxLen = length(endWorldPos - curPos);
                half3 dir = normalize(endWorldPos - curPos);

                int maxStep = 300;
                half stepDt = 0.05;
                half3 dt = 0;;

                for(int i = 0 ; i < maxStep; i++)
                {
                    dt += dir * stepDt;
                    color += GetShadow(curPos + dt) * 0.003f;
                    if(length(dt) > maxLen) break;
                }
                    
                return color;
            }
            ENDHLSL
        }
    }
}
