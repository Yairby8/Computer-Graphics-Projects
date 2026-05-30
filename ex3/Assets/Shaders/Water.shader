Shader "CG/Water"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        _TimeScale("Time Scale", Range(0.1, 5)) = 3 
        _BumpScale("Bump Scale", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "CGUtils.cginc"
            #include "CGRandom.cginc"

            #define DELTA 0.01

            // Declare used properties
            uniform samplerCUBE _CubeMap;
            uniform float _NoiseScale;
            uniform float _TimeScale;
            uniform float _BumpScale;

            struct appdata
            { 
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                float2 uv       : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos      : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 worldTangent: TEXCOORD3;
            };

            // Returns the value of a noise function simulating water, at coordinates uv and time t
            float waterNoise(float2 uv, float t)
            {
                // For now, ignore time and just sample 2D Perlin noise at the given UV
                // float n = perlin2d(uv);      

                float u = uv.x;
                float v = uv.y;

                // First octave: lower frequency, slower time
                float n1 = perlin3d(float3(0.5 * u, 0.5 * v, 0.5 * t));

                // Second octave: base frequency, base time
                float n2 = perlin3d(float3(u, v, t));

                // Third octave: higher frequency, faster time
                float n3 = perlin3d(float3(2.0 * u, 2.0 * v, 3.0 * t));

                // Combine with given weights:
                // Perlin3D(0.5u,0.5v,0.5t) + 0.5*Perlin3D(u,v,t) + 0.2*Perlin3D(2u,2v,3t)
                float n = n1 + 0.5 * n2 + 0.2 * n3;

                return n;                
            }

            // Returns the world-space bump-mapped normal for the given bumpMapData and time t
            float3 getWaterBumpMappedNormal(bumpMapData i, float t)
            {
                // Sample procedural "height" from waterNoise at UV and neighbors
                float hC = waterNoise(i.uv, t);                          // center
                float hU = waterNoise(i.uv + float2(DELTA, 0.0), t);     // u+delta
                float hV = waterNoise(i.uv + float2(0.0, DELTA), t);     // v+delta

                // Finite differences for partial derivatives
                float fu = (hU - hC) / DELTA;   // dh/du
                float fv = (hV - hC) / DELTA;   // dh/dv

                // Scale by bump amplitude
                fu *= i.bumpScale;
                fv *= i.bumpScale;

                // Tangent-space normal from slopes
                float3 n_tan = normalize(float3(-fu, -fv, 1.0));

                // Build TBN basis in world space
                float3 N = normalize(i.normal);
                float3 T = normalize(i.tangent);
                float3 B = normalize(cross(N, T));

                // Transform tangent-space normal to world space
                float3 n_world =
                n_tan.x * T +
                n_tan.y * B +
                n_tan.z * N;

            return normalize(n_world);  
            }


            v2f vert (appdata input)
            {
                v2f output;

                // Scale UVs for noise sampling
                float2 scaledUV = input.uv * _NoiseScale;

                // Sample 2D Perlin noise at this UV
                // float noise = perlin2d(scaledUV);   // ≈ [-1, 1]

                float t = _Time.y * _TimeScale; // base time in seconds times the scale
                float noise = waterNoise(scaledUV, t);   

                // Compute displacement
                float displacement = noise * _BumpScale;

                // Displace vertex along up axis (y)
                float4 displacedVertex = input.vertex;
                displacedVertex.y += displacement;

                // Displaced position
                output.pos = UnityObjectToClipPos(displacedVertex);

                // World-space position
                float4 worldPos = mul(unity_ObjectToWorld, displacedVertex);
                output.worldPos = worldPos.xyz;

                // World-space normal (assuming uniform scale)
                output.worldNormal = normalize(
                mul((float3x3)unity_ObjectToWorld, input.normal)
                );

                // World-space tangent
                output.worldTangent = normalize(
                mul((float3x3)unity_ObjectToWorld, input.tangent.xyz)
                );

                output.uv = scaledUV;
                
                return output;
            }

            fixed4 frag (v2f input) : SV_Target
            {
                // View direction: from surface to camera
                float3 v = normalize(_WorldSpaceCameraPos - input.worldPos);

                // ---- Build bumpMapData for this fragment ----
                bumpMapData data;
                data.normal    = input.worldNormal;   // base mesh normal (world-space)
                data.tangent   = input.worldTangent;  // world-space tangent
                data.uv        = input.uv;            // already scaled UV
                data.du        = DELTA;               // per instructions
                data.dv        = DELTA;               // per instructions
                data.bumpScale = _BumpScale;          // per instructions
                // data.heightMap is ignored by getWaterBumpMappedNormal

                float t = _Time.y * _TimeScale; // base time in seconds times the scale

                // Bump-mapped water normal (world-space)
                float3 n = getWaterBumpMappedNormal(data, t);

                float3 r = 2.0 * dot(v,n) * n - v;       // reflected direction

                // Sample cube map with reflected direction
                fixed4 reflectedColor = texCUBE(_CubeMap, r);

                // Angle-based reflection factor
                float ndotv = max(0.0, dot(n, v));
                float factor = 1.0 - ndotv + 0.2;

                // Final color
                fixed3 color = factor * reflectedColor.rgb;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}
