Shader "CG/BlinnPhongGouraud"
{
    Properties
    {
        _DiffuseColor ("Diffuse Color", Color) = (0.14, 0.43, 0.84, 1)
        _SpecularColor ("Specular Color", Color) = (0.7, 0.7, 0.7, 1)
        _AmbientColor ("Ambient Color", Color) = (0.05, 0.13, 0.25, 1)
        _Shininess ("Shininess", Range(0.1, 50)) = 10
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" } 

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // Declare used properties
            uniform fixed4 _DiffuseColor;
            uniform fixed4 _SpecularColor;
            uniform fixed4 _AmbientColor;
            uniform float _Shininess;

            struct appdata
            { 
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR0; // addition of varying    
            };


            v2f vert (appdata input)
            {
                v2f output;
                output.pos = UnityObjectToClipPos(input.vertex);

                // World-space position & normal
                float3 worldPos    = mul(unity_ObjectToWorld, input.vertex).xyz;
                // Multiply M^(-1) by the normal
                // float3 worldNormal = normalize(mul((float3x3)unity_WorldToObject, input.normal));

                float3 worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, input.normal));


                // Direction towards the light
                float3 L = normalize(_WorldSpaceLightPos0.xyz);

                // Direction towards the camera
                float3 V = normalize(_WorldSpaceCameraPos - worldPos);

                // Blinn-Phong half vector
                float3 H = normalize(L + V);

                // Diffuse term
                float LdotN = max(0.0, dot(L, worldNormal));
                fixed3 diffuse = _DiffuseColor.rgb * _LightColor0.rgb * LdotN;

                // Specular term 

                // Phong model
                // float RdotV = max(0.0, dot(2 * LdotN * worldNormal - L, V));
                // fixed3 specular = _SpecularColor.rgb * _LightColor0.rgb * pow(RdotV, _Shininess);

                // Blinn-Phong model
                float NdotH = max(0.0, dot(H, worldNormal));
                fixed3 specular = _SpecularColor.rgb * _LightColor0.rgb * pow(NdotH, _Shininess);

                // Ambient term
                fixed3 ambient = _AmbientColor.rgb * _LightColor0.rgb;

                // Final vertex color (Gouraud: lighting per vertex)
                fixed3 finalColor = ambient + diffuse + specular;

                output.color = fixed4(finalColor, 1.0);

                return output;
            }


            fixed4 frag (v2f input) : SV_Target
            {
                return input.color;
            }

            ENDCG
        }
    }
}
