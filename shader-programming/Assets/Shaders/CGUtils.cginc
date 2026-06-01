#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653

// A struct containing all the data needed for bump-mapping
struct bumpMapData {
    float3 normal;       // Mesh surface normal at the point
    float3 tangent;      // Mesh surface tangent at the point
    float2 uv;           // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du;            // Increment size for u partial derivative approximation
    float dv;            // Increment size for v partial derivative approximation
    float bumpScale;     // Bump scaling factor
};

// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos) {
    // Extract coordinates
    float x = pos.x;
    float y = pos.y;
    float z = pos.z;

    // Radius (distance from origin)
    float r = length(pos);

    // Avoid division by zero 
    // if (r == 0.0)
    // {
    //     return float2(0.0, 0.0);
    // }F

    // Spherical angles
    // Longitude around Y axis: theta = atan2(z, x)
    float theta = atan2(z, x);

    // Latitude from +Y: phi = acos(y / r)
    float phi = acos(clamp(y / r, -1.0, 1.0));
    // Map to [0,1] range
    float u = 0.5 + theta / (2.0 * PI);
    float v = 1.0 - phi / PI;

    return float2(u, v);
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity) {
    // Make sure all direction vectors are normalized
    n = normalize(n);
    v = normalize(v);
    l = normalize(l);

    // Halfway vector between view and light
    float3 h = normalize(v + l);

    // ----- Ambient -----
    fixed3 ambient = ambientIntensity * albedo.rgb;

    // ----- Diffuse -----
    float ndotl = max(0.0, dot(n, l));
    fixed3 diffuse = ndotl * albedo.rgb;

    // ----- Specular (Blinn-Phong) -----
    float ndoth = max(0.0, dot(n, h));
    float specFactor = pow(ndoth, shininess);
    fixed3 specular = specFactor * specularity.rgb;

    // Sum of components
    return ambient + diffuse + specular;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i) {
    bumpMapData data = i;
    // Normalize the input basis
    float3 N = normalize(data.normal);
    float3 T = normalize(data.tangent);
    float3 B = normalize(cross(N, T));   // bitangent (world-space)

    // Sample heightmap around current UV
    // Assuming r=g=b=a and the color in the height map represents height

    // Center height
    float hC = tex2D(data.heightMap, data.uv).r;

    // Height a small step in +u
    float hU = tex2D(data.heightMap, data.uv + float2(data.du, 0.0)).r;

    // Height a small step in +v
    float hV = tex2D(data.heightMap, data.uv + float2(0.0, data.dv)).r;

    // Approximate partial derivatives of the height field
    float dhdu = (hU - hC) / data.du;
    float dhdv = (hV - hC) / data.dv;

    // Tangent-space bumped normal (z points out of the surface)
    float3 nTangent = float3(
        -dhdu * data.bumpScale,
        -dhdv * data.bumpScale,
        1.0);

    nTangent = normalize(nTangent);

    // Transform from tangent space to world space:
    // (T, B, N) is the basis for tangent space in world coordinates
    float3 bumpedWorldNormal =
    nTangent.x * T +
    nTangent.y * B +
    nTangent.z * N;

    return normalize(bumpedWorldNormal);
}

#endif // CG_UTILS_INCLUDED
