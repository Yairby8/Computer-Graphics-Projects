Shader "CG/BlinnPhong"
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
                //data passed from vertex shader to fragment shader
                
                float4 pos : SV_POSITION;
                float3 worldPos    : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            // Calculates diffuse lighting of secondary point lights (part 3)
            fixed4 pointLights(v2f input)
            {
                // Normalized world-space normal
                float3 N = normalize(input.worldNormal);

                fixed3 totalDiffuse = fixed3(0, 0, 0);

                // Loop over 4 point lights
                for (int i = 0; i < 4; i++)
                {
                    // World-space position of light i
                    float3 lightPos = float3(
                    unity_4LightPosX0[i],
                    unity_4LightPosY0[i],
                    unity_4LightPosZ0[i]
                    );

                    // Vector from point to light
                    float3 toLight = lightPos - input.worldPos;
                    float  distSq  = dot(toLight, toLight);
                    float3 L       = normalize(toLight);

                    // Simple attenuation using unity_4LightAtten0
                    float attenuation = 1.0 / (1.0 + distSq * unity_4LightAtten0[i]);

                    // Diffuse term: c * i = k_d * C_light * max(0, L dot N) * attenuation
                    float  LdotN   = max(0.0, dot(L, N));
                    fixed3 diffuse = _DiffuseColor.rgb * unity_LightColor[i].rgb * LdotN * attenuation;

                    // Non-defined lights default to zero and don't affect the result                    
                    totalDiffuse += diffuse;
                }

                return fixed4(totalDiffuse, 1.0);
            }


            v2f vert (appdata input)
            {
                v2f output;
                output.pos = UnityObjectToClipPos(input.vertex);

                // World-space position and normal
                output.worldPos    = mul(unity_ObjectToWorld, input.vertex).xyz;
                // Multiply M^(-1) by the normal
                output.worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, input.normal));

                // output.worldNormal = normalize(
                // unity_WorldToObject[0].xyz * input.normal.x +
                // unity_WorldToObject[1].xyz * input.normal.y +
                // unity_WorldToObject[2].xyz * input.normal.z
                // );


                return output;

            }


            fixed4 frag (v2f input) : SV_Target
            {

                // Normalize interpolated normal
                float3 N = normalize(input.worldNormal);

                // Direction towards the light
                float3 L = normalize(_WorldSpaceLightPos0.xyz);

                // Direction towards the camera
                float3 V = normalize(_WorldSpaceCameraPos - input.worldPos);

                // Blinn-Phong half vector
                float3 H = normalize(L + V);

                
                // Diffuse term
                float LdotN = max(0.0, dot(L, N));
                fixed3 diffuse = _DiffuseColor.rgb * _LightColor0.rgb * LdotN;

                // Specular term 

                // Blinn-Phong model
                float NdotH = max(0.0, dot(H, N));
                fixed3 specular = _SpecularColor.rgb * _LightColor0.rgb * pow(NdotH, _Shininess);


                // Ambient term
                fixed3 ambient = _AmbientColor.rgb * _LightColor0.rgb;

                // Final pixel color (Phong: lighting per pixel)
                fixed3 mainLight = ambient + diffuse + specular;

                // Add point-light contribution (part 3)
                fixed4 pointCol = pointLights(input);

                fixed3 finalColor = mainLight + pointCol.rgb;

                return fixed4(finalColor, 1.0);

            }

            ENDCG
        }
    }
}
