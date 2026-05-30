Shader "CG/Earth"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(1, 100)) = 30
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "black" {}
        _AtmosphereColor ("Atmosphere Color", Color) = (0.8, 0.85, 1, 1)
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
            #include "CGUtils.cginc"

            // Declare used properties
            uniform sampler2D _AlbedoMap;
            uniform float _Ambient;
            uniform sampler2D _SpecularMap;
            uniform float _Shininess;
            uniform sampler2D _HeightMap;
            uniform float4 _HeightMap_TexelSize;
            uniform float _BumpScale;
            uniform sampler2D _CloudMap;
            uniform fixed4 _AtmosphereColor;

            struct appdata
            { 
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;



            };

            v2f vert (appdata input)
            {
                v2f output;
                output.pos = UnityObjectToClipPos(input.vertex);
                
                // world space:
                output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
                return output;
            }

            fixed4 frag (v2f input) : SV_Target
            {

                // Reconstruct per-fragment direction & normal from position
                float3 dir = normalize(input.worldPos); // direction from center
                float3 baseNormal   = dir;                   // normal for a sphere

                // Spherical UV mapping
                float2 uv = getSphericalUV(dir);

                // Sample albedo and specular maps
                fixed4 albedo      = tex2D(_AlbedoMap,    uv);
                fixed4 specularity = tex2D(_SpecularMap,  uv);

                // View and light directions in world space
                float3 viewDir  = normalize(_WorldSpaceCameraPos - input.worldPos);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                // Lambert term
                float lambert = max(0.0, dot(baseNormal, lightDir));


                // Atmosphere term
                float ndotv = max(0.0, dot(baseNormal, viewDir));
                float atmosphereFactor = (1.0 - ndotv) * sqrt(lambert);
                float3 atmosphere = atmosphereFactor * _AtmosphereColor.rgb;

                // Cloud term
                fixed4 cloudSample = tex2D(_CloudMap, uv);
                float cloudLighting = sqrt(lambert) + _Ambient;
                float3 clouds = cloudSample.rgb * cloudLighting;



                // ---- Build bumpMapData for getBumpMappedNormal ----
                float3 up = float3(0.0, 1.0, 0.0);

                bumpMapData data;
                data.normal    = baseNormal;
                data.tangent   = normalize(cross(baseNormal, up));
                data.uv        = uv;
                data.heightMap = _HeightMap;

                // Use texel size as du, dv (may not be square)
                data.du = _HeightMap_TexelSize.x; // 1 / width
                data.dv = _HeightMap_TexelSize.y; // 1 / height

                // Bump scale is _BumpScale / 10000, as required
                data.bumpScale = _BumpScale / 10000.0;

                // Get world-space bump-mapped normal
                float3 bumpedNormal = getBumpMappedNormal(data);

                // Sample specular map as water mask
                fixed4 specSample = tex2D(_SpecularMap, uv);
                float water = specSample.r;   // assume grayscale spec map, r = water amount

                // Blend normals: land -> bumpedNormal, water -> baseNormal
                float3 finalNormal =
                normalize( (1.0 - water) * bumpedNormal +
                water         * baseNormal );

                // ---- Blinn-Phong shading without bumped normal ----

                // fixed3 litColor = blinnPhong(
                // baseNormal,
                // viewDir,
                // lightDir,
                // _Shininess,
                // albedo,
                // specularity,
                // _Ambient
                // );


                
                // ---- Blinn-Phong shading with bumped normal ----

                // fixed3 litColor = blinnPhong(
                // bumpedNormal,
                // viewDir,
                // lightDir,
                // _Shininess,
                // albedo,
                // specularity,
                // _Ambient
                // );

                // ---- Blinn-Phong shading with blended normal ----
                fixed3 litColor = blinnPhong(
                finalNormal,
                viewDir,
                lightDir,
                _Shininess,
                albedo,
                specularity,
                _Ambient
                );

                fixed3 finalColor = litColor + atmosphere + clouds;
                return fixed4(finalColor, 1.0);
            }

            ENDCG
        }
    }
}
