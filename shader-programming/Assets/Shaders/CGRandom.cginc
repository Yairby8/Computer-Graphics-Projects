#ifndef CG_RANDOM_INCLUDED
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
#define CG_RANDOM_INCLUDED

// Returns a psuedo-random float between -1 and 1 for a given float c
float random(float c)
{
    return -1.0 + 2.0 * frac(43758.5453123 * sin(c));
}

// Returns a psuedo-random float2 with componenets between -1 and 1 for a given float2 c 
float2 random2(float2 c)
{
    c = float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)));

    float2 v = -1.0 + 2.0 * frac(43758.5453123 * sin(c));
    return v;
}

// Returns a psuedo-random float3 with componenets between -1 and 1 for a given float3 c 
float3 random3(float3 c)
{
    float j = 4096.0 * sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    r = -1.0 + 2.0 * r;
    return r.yzx;
}

// Interpolates a given array v of 4 float values using bicubic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
//
// [0]=====o==[1]
//         |
//         t
//         |
// [2]=====o==[3]
//
float bicubicInterpolation(float v[4], float2 t)
{
    float2 u = t * t * (3.0 - 2.0 * t); // Cubic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 4 float values using biquintic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
float biquinticInterpolation(float v[4], float2 t)
{
    // Quintic Hermite curve function
    float2 u = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction
    return lerp(x1, x2, u.y);}

// Interpolates a given array v of 8 float values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
float triquinticInterpolation(float v[8], float3 t)
{
    // Quintic Hermite fade in each dimension
    float3 u = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);

    // Interpolate along X for z = 0 layer
    float x00 = lerp(v[0], v[1], u.x);  // (0,0,0) -> (1,0,0)
    float x10 = lerp(v[2], v[3], u.x);  // (0,1,0) -> (1,1,0)

    // Interpolate along X for z = 1 layer
    float x01 = lerp(v[4], v[5], u.x);  // (0,0,1) -> (1,0,1)
    float x11 = lerp(v[6], v[7], u.x);  // (0,1,1) -> (1,1,1)

    // Interpolate along Y (between rows) for each z
    float y0 = lerp(x00, x10, u.y);     // z = 0
    float y1 = lerp(x01, x11, u.y);     // z = 1

    // Interpolate along Z between the two layers
    return lerp(y0, y1, u.z);}

// Returns the value of a 2D value noise function at the given coordinates c
float value2d(float2 c)
{
    float2 cellMin = floor(c);   // bottom-left integer corner of the cell
    float2 t       = c - cellMin; // fractional part in [0,1)^2}

    // Compute 4 points
    float2 p0 = cellMin + float2(0.0, 0.0); // v[0]
    float2 p1 = cellMin + float2(1.0, 0.0); // v[1]
    float2 p2 = cellMin + float2(0.0, 1.0); // v[2]
    float2 p3 = cellMin + float2(1.0, 1.0); // v[3]


    float v[4];
    v[0] = random2(p0).x;
    v[1] = random2(p1).x;
    v[2] = random2(p2).x;
    v[3] = random2(p3).x;

    return bicubicInterpolation(v, t);

}

// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{
    float2 cell = floor(c);       // bottom-left integer corner of the cell
    float2 f    = c - cell;       // fractional part in [0,1)^2}

    // random gradient vector for each cell
    float2 g00 = normalize(random2(cell + float2(0.0, 0.0)));
    float2 g10 = normalize(random2(cell + float2(1.0, 0.0)));
    float2 g01 = normalize(random2(cell + float2(0.0, 1.0)));
    float2 g11 = normalize(random2(cell + float2(1.0, 1.0)));

    // offset vectors
    float2 d00 = f - float2(0.0, 0.0);  // = f
    float2 d10 = f - float2(1.0, 0.0);
    float2 d01 = f - float2(0.0, 1.0);
    float2 d11 = f - float2(1.0, 1.0);

    // calculate influence values
    float v[4];
    v[0] = dot(g00, d00);
    v[1] = dot(g10, d10);
    v[2] = dot(g01, d01);
    v[3] = dot(g11, d11);

    // return bicubicInterpolation(v, f);

    return biquinticInterpolation(v, f);

}


// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{                    
    // Integer cell and local coords
    float3 cell = floor(c);    // (i, j, k)
    float3 f    = c - cell;    // in [0,1)^3

    // Gradient vectors at the 8 corners
    float3 g000 = normalize(random3(cell + float3(0.0, 0.0, 0.0)));
    float3 g100 = normalize(random3(cell + float3(1.0, 0.0, 0.0)));
    float3 g010 = normalize(random3(cell + float3(0.0, 1.0, 0.0)));
    float3 g110 = normalize(random3(cell + float3(1.0, 1.0, 0.0)));
    float3 g001 = normalize(random3(cell + float3(0.0, 0.0, 1.0)));
    float3 g101 = normalize(random3(cell + float3(1.0, 0.0, 1.0)));
    float3 g011 = normalize(random3(cell + float3(0.0, 1.0, 1.0)));
    float3 g111 = normalize(random3(cell + float3(1.0, 1.0, 1.0)));

    // Offsets from corners to point
    float3 d000 = f - float3(0.0, 0.0, 0.0);
    float3 d100 = f - float3(1.0, 0.0, 0.0);
    float3 d010 = f - float3(0.0, 1.0, 0.0);
    float3 d110 = f - float3(1.0, 1.0, 0.0);
    float3 d001 = f - float3(0.0, 0.0, 1.0);
    float3 d101 = f - float3(1.0, 0.0, 1.0);
    float3 d011 = f - float3(0.0, 1.0, 1.0);
    float3 d111 = f - float3(1.0, 1.0, 1.0);

    // Corner influences
    float v[8];
    v[0] = dot(g000, d000);
    v[1] = dot(g100, d100);
    v[2] = dot(g010, d010);
    v[3] = dot(g110, d110);
    v[4] = dot(g001, d001);
    v[5] = dot(g101, d101);
    v[6] = dot(g011, d011);
    v[7] = dot(g111, d111);

    // Triquintic interpolation with local coords f
    float n = triquinticInterpolation(v, f);
    return n;
    }


#endif // CG_RANDOM_INCLUDED
