Shader "CG/Bricks"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture"{}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture"{}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture"{}
        _BumpScale ("Bump Scale", Range(-100, 100)) = 40
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "CGUtils.cginc"

            // Declare used properties
            uniform sampler2D _AlbedoMap;
            uniform float _Ambient;
            uniform sampler2D _SpecularMap;
            uniform float _Shininess;
            uniform sampler2D _HeightMap;
            uniform float4 _HeightMap_TexelSize;
            uniform float _BumpScale;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;  // interpolated UV coords, added in part 1
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 worldTangent : TEXCOORD3; // added for part 6
            };

            v2f vert (appdata input)
            {
                v2f output;
                // clip-space position
                output.pos = UnityObjectToClipPos(input.vertex);   
                // forward the mesh UV coords
                output.uv = input.uv; 
                
                // world position
                float4 worldPos = mul(unity_ObjectToWorld, input.vertex);
                output.worldPos = worldPos.xyz;

                // world normal
                // unity + hlsl implementation of matrix multiplication ensures this is equivalent
                // to multiplying the transpose of the inverse transformation matrix by the normal vector
                // https://discussions.unity.com/t/recalculate-normal-from-object-to-world-the-simplest-way/666230/2

                output.worldNormal  = normalize(mul((float3x3)unity_ObjectToWorld, input.normal));

                //equivalent to multipying the transpose of inverse
                // output.worldNormal = normalize(
                // unity_WorldToObject[0].xyz * input.normal.x +
                // unity_WorldToObject[1].xyz * input.normal.y +
                // unity_WorldToObject[2].xyz * input.normal.z
                // );

                output.worldTangent = normalize(
                mul((float3x3)unity_ObjectToWorld, input.tangent.xyz)
                );

                return output;
            }

            fixed4 frag (v2f input) : SV_Target
            {
                // part 1 q6
                // View and light directions in world space
                float3 viewDir  = normalize(_WorldSpaceCameraPos - input.worldPos);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                // Sample albedo and specular maps
                fixed4 albedo      = tex2D(_AlbedoMap,    input.uv);
                fixed4 specularity = tex2D(_SpecularMap,  input.uv);

                // ---- Build bumpMapData for getBumpMappedNormal ----
                bumpMapData data;
                data.normal    = normalize(input.worldNormal);
                data.tangent   = normalize(input.worldTangent);
                data.uv        = input.uv;
                data.heightMap = _HeightMap;

                // Use texel size as du, dv (may not be square)
                data.du = _HeightMap_TexelSize.x; // 1 / width
                data.dv = _HeightMap_TexelSize.y; // 1 / height

                // Bump scale is _BumpScale / 10000, as required
                data.bumpScale = _BumpScale / 10000.0;

                // Get world-space bump-mapped normal
                float3 bumpedNormal = getBumpMappedNormal(data);

                // ---- Blinn-Phong shading with bumped normal ----
                fixed3 litColor = blinnPhong(
                bumpedNormal,
                viewDir,
                lightDir,
                _Shininess,
                albedo,
                specularity,
                _Ambient
                );

                return fixed4(litColor, 1.0);

            }

            ENDCG
        }
    }
}
