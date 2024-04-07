Shader "TestInstancing"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }
        
        Pass
        {
            Name "Unlit"
            Cull Off
            ZWrite On
            
            HLSLPROGRAM

            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            // #pragma multi_compile_instancing
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;

                float4 color : COLOR;
                uint instanceID : SV_InstanceID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 posWS : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;

                float4 color : COLOR;
                uint instanceID : SV_InstanceID;
            };

            float4 _Color;
            StructuredBuffer<float4x4> testStructuredBuffer;

            float2 hash( float2 p ) 
            {
	            p = float2( dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)) );
	            return -1.0 + 2.0*frac(sin(p)*43758.5453123);
            }

            float noise( in float2 p )
            {
                const float K1 = 0.366025404;
                const float K2 = 0.211324865;

	            float2  i = floor( p + (p.x+p.y)*K1 );
                float2  a = p - i + (i.x+i.y)*K2;
                float m = step(a.y,a.x); 
                float2  o = float2(m,1.0-m);
                float2  b = a - o + K2;
	            float2  c = a - 1.0 + 2.0*K2;
                float2  h = max( 0.5-float3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	            float2  n = h*h*h*h*float3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
                return dot( n, float3(70.0, 70.0, 70.0));
            }
            
            float wave(inout float3 posWS, float time)
            {
                float offset = noise(posWS.xz * 0.1+time.x)* 0.4 * posWS.y;
                posWS.z += offset;
                return offset;
            }
            
            Varyings UnlitPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float4x4 transform = testStructuredBuffer[input.instanceID];
                float4x4 MVP = mul(UNITY_MATRIX_VP, transform);
                float3 normalWS = mul(input.normal, (float3x3) transpose(Inverse(transform)));

                output.normal = normalWS;
                output.posWS = mul(transform, input.positionOS);
                float offset = wave(output.posWS, _Time.y*1);
                output.positionCS = mul(UNITY_MATRIX_VP, float4(output.posWS, 1));
                output.shadowCoord = TransformWorldToShadowCoord(output.posWS);
                
                output.color = input.color - offset;
                return output;
            }

            float halfLambert(float3 l, float3 n)
            {
                return dot(l, n) * 0.5 + 0.5;
            }

            half4 UnlitPassFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                float4 outColor = input.color * _Color;
                Light mainLight = GetMainLight(input.shadowCoord);
                
                float bright = halfLambert(mainLight.direction, input.normal)*0.5 + halfLambert(mainLight.direction, input.normal)*0.5;
                outColor.rgb *= bright * mainLight.color * (mainLight.shadowAttenuation*0.5+0.5);
                return outColor;
            }
            ENDHLSL
        }
    }
}