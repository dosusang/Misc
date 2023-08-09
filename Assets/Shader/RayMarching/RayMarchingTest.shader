Shader "Unlit/RayMarchingTest"
{
    Properties
    {
        _MainTex ("Example Texture", 2D) = "white" {}
        _CamColorTex ("Example Texture", 2D) = "white" {}
        _DownSample("_DownSample", int) = 1
        _UpdateChannel("_DownSample", int) = 1

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

        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float2 uv: TEXCOORD0;
        };

        struct Varyings2
        {
            float4 positionCS : SV_POSITION;
            float4 uvAndPosSS : TEXCOORD0;
        };

        Varyings UnlitPassVertex(Attributes input)
        {
            Varyings output;

            VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
            output.positionCS = positionInputs.positionCS;

            output.uv = input.uv;
            return output;
        }

        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        float4 _BaseColor;
        uint _UpdateChannel;

        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "VolumeLight"
            blend one zero

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            float _DownSample;

            float GetShadow(float3 positionWS)
            {
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                float shadow = MainLightRealtimeShadow(shadowCoord);
                return shadow;
            }

            // 重建世界空间位置。
            float3 GetWorldPos(float2 uv)
            {
                #if UNITY_REVERSED_Z
                real depth = SampleSceneDepth(uv);
                #else
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
                #endif

                float3 worldPos = ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
                return worldPos;
            }

            float4 UnlitPassFragment(Varyings2 input) : SV_Target
            {
                float4 color = 0;
                float2 screenUV = input.positionCS.xy / (_ScaledScreenParams.xy * _DownSample);
                
                float2 channel = floor(input.positionCS);
                // 棋盘格刷新
                clip(channel.y%2 * channel.x%2 + (channel.y+1)%2 * (channel.x+1)%2 - 0.1f);
                
                float3 endWorldPos = GetWorldPos(screenUV);
                float3 curPos = _WorldSpaceCameraPos;
                float maxLen = min(length(endWorldPos - curPos), 20);
                float3 dir = normalize(endWorldPos - curPos);

                uint maxStep = 300;
                float stepDt = 0.025;
                float intensityPerStep = 0.015f;
                float3 dt = 0;;

                for (uint i = 0; i < maxStep; i++)
                {
                    stepDt *= 1.02f;
                    dt += dir * stepDt;
                    if (length(dt) > maxLen) break;
                    color += GetShadow(curPos + dt) * intensityPerStep;
                }
                color.rgb *= GetMainLight().color;
                return smoothstep(0,5, color) * 0.5;
            }
            ENDHLSL
        }

        pass
        {
            Name "BlurH"
            zwrite off

            HLSLPROGRAM
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            float4 UnlitPassFragment(Varyings input) : SV_Target
            {
                float4 color = 0;
                const float kernel[] = {0.4,0.25,0.05};
                for(int i = -2; i <=2 ; i++)
                {
                    color += kernel[abs(i)] * tex2D(_MainTex, input.uv + float2(0, i) * _MainTex_TexelSize.xy);
                }
                return color;
            }
            ENDHLSL
        }
        
        
        pass
        {
            Name "BlurV"
            zwrite off

            HLSLPROGRAM
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            
            sampler2D _CamColorTex;


            float4 UnlitPassFragment(Varyings input) : SV_Target
            {
                float4 color = 0;
                for(int i = -2; i <=2 ; i++)
                {
                    const float kernel[] = {0.4,0.25,0.05};
                    color += kernel[abs(i)] * tex2D(_MainTex, input.uv + float2(i,0) * _MainTex_TexelSize.xy);
                }
                return color;
            }
            ENDHLSL
        }
        
        pass
        {
            Name "BlurVAndBlend"
            zwrite off
            Blend One One

            HLSLPROGRAM
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            
            sampler2D _CamColorTex;


            float4 UnlitPassFragment(Varyings input) : SV_Target
            {
                float4 color = 0;
                for(int i = -2; i <=2 ; i++)
                {
                    const float kernel[] = {0.4,0.25,0.05};
                    color += kernel[abs(i)] * tex2D(_MainTex, input.uv + float2(i,0) * _MainTex_TexelSize.xy);
                }
                return color;
            }
            ENDHLSL
        }
    }
}