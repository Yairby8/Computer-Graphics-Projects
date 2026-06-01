// Checks for an intersection between a ray and a sphere
// The sphere center is given by sphere.xyz and its radius is sphere.w
void intersectSphere(Ray ray, inout RayHit bestHit, Material material, float4 sphere)
{
    float3 C = sphere.xyz; // sphere center
    float  r = sphere.w; // sphere radius

    float3 oc = ray.origin - C;
    // We need to satisfy:
    // 1. p = ray(t) = o + dt (point is on the ray)
    // 2. ||p - C|| = r (point is on the sphere)
    // Solve: |oc + t*d|^2 = r^2  =>  a t^2 + b t + c = 0 (quadratic equation)
    float a = dot(ray.direction, ray.direction); // Should be 1 because it's normalized
    float b = 2.0f * dot(oc, ray.direction);
    float c = dot(oc, oc) - r * r;

    float disc = b * b - 4.0f * a * c;
    if (disc < 0.0f) return;

    float s = sqrt(disc);

    // Two candidate roots
    float t0 = (-b - s) / (2.0f * a); // near hit (entering the sphere)
    float t1 = (-b + s) / (2.0f * a); // far hit (exitting the sphere)

    // Pick the closest t that is in front of the ray (t > 0 + epsilon)
    float t = 1.#INF; // init value before t is chosen
    if (t0 > EPS) t = t0;
    else if (t1 > EPS) t = t1; // origin is inside the sphere
    else return; // both behind / too close (origin is past the sphere)

    // If it's not better than what we already have, ignore
    // Since d is normalized, dt = t = ray to object distance
    if (t >= bestHit.distance) return;

    // Fill bestHit
    bestHit.distance  = t;
    bestHit.position  = ray.origin + t * ray.direction;

    bestHit.normal = normalize(bestHit.position - C); // outward geometric normal (vector that points from the center of the sphere to the surface point)
    bestHit.material  = material;
}
    

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
void intersectPlane(Ray ray, inout RayHit bestHit, Material material, float3 c, float3 n)
{
    float3 N = normalize(n);

    // If ray is parallel to the plane, no hit
    float dDotN = dot(ray.direction, N);
    if (abs(dDotN) < EPS) return;

    // We need to satisfy:
    // 1. p = ray(t) = o + dt (point is on the ray)
    // 2. dot(p - c, n) = 0 (point is on the plane)
    // Solve for t: dot(O + td - c, N) = dot(o - c, N) + dot(d, N) * t = 0  =>  t = -dot(O - c, N) / dot(d, N)
    float t = -1.0f * dot(ray.origin - c, N) / dDotN;

    // Hit must be in front of the ray origin (and not too close)
    if (t <= EPS) return;

    // Keep only the closest hit so far
    if (t >= bestHit.distance) return;

    // Fill bestHit
    bestHit.distance = t;
    bestHit.position = ray.origin + t * ray.direction;

    bestHit.normal = N; // geometric plane normal (as provided)
    bestHit.material = material;
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
// The material returned is either m1 or m2 in a way that creates a checkerboard pattern 
void intersectPlaneCheckered(Ray ray, inout RayHit bestHit, Material m1, Material m2, float3 c, float3 n)
{
    float3 N = normalize(n);
    float dDotN = dot(ray.direction, N);

    // Standard Plane Intersection logic
    if (abs(dDotN) < EPS) return;

    float t = dot(c - ray.origin, N) / dDotN;
    if (t <= EPS || t >= bestHit.distance) return;

    // Fill basic hit info
    bestHit.distance = t;
    bestHit.position = ray.origin + t * ray.direction;
    bestHit.normal = N;

    // Checkerboard logic
    // Squares are 0.5 units, so we scale coordinates by 2.0
    float3 p = bestHit.position * 2.0f; 
    
    // We sum the floored coordinates to create the grid 
    // Using floor(p.x) + floor(p.y) + floor(p.z) ensures it works for any axis-aligned plane
    float check = floor(p.x + EPS) + floor(p.y + EPS) + floor(p.z + EPS);
    
    // Use modulo function to alternate materials
    if (fmod(abs(check), 2.0) < 1.0) {
        bestHit.material = m1;
    } else {
        bestHit.material = m2;
    }
}


// Checks for an intersection between a ray and a triangle
// The triangle is defined by points a, b, c
void intersectTriangle(Ray ray, inout RayHit bestHit, Material material, float3 a, float3 b, float3 c, bool drawBackface = false)
{
    float3 edge1 = b - a;
    float3 edge2 = c - a;
    float3 normal = cross(edge1, edge2);
    float3 N = normalize(normal);

    // Plane Intersection Logic
    float dDotN = dot(ray.direction, N);
    
    // Check backface culling 
    // If dot(d, N) > 0, we are hitting the back of the triangle, else we are hitting the front
    if (!drawBackface && dDotN > 0.0f) return;
    
    // If dot(d, N) is near 0, ray is parallel to triangle plane
    if (abs(dDotN) < EPS) return;

    float t = dot(a - ray.origin, N) / dDotN;

    //  Early exit if hit is behind ray or further than bestHit
    if (t <= EPS || t >= bestHit.distance) return;

    //  Inside-triangle test (following the descriptions in TA7)
    float3 p = ray.origin + t * ray.direction;

    float s0 = dot(cross(b - a, p - a), N);
    float s1 = dot(cross(c - b, p - b), N);
    float s2 = dot(cross(a - c, p - c), N);

    bool inside;
    if (drawBackface)
    {
        // Accept either orientation (all non-negative OR all non-positive)
        inside = (s0 >= 0.0f && s1 >= 0.0f && s2 >= 0.0f) ||
                 (s0 <= 0.0f && s1 <= 0.0f && s2 <= 0.0f);
    }
    else
    {
        // Front face only (consistent with n's winding)
        inside = (s0 >= 0.0f && s1 >= 0.0f && s2 >= 0.0f);
    }


    if (!inside) return;

    //  Fill bestHit 
    bestHit.distance = t;
    bestHit.position = p;
    bestHit.normal = N;
    bestHit.material = material;

}


// Checks for an intersection between a ray and a 2D circle
// The circle center is given by circle.xyz, its radius is circle.w and its orientation vector is n 
void intersectCircle(Ray ray, inout RayHit bestHit, Material material, float4 circle, float3 n, bool drawBackface = false)
{
    float3 c = circle.xyz;
    float  r = circle.w;

    float3 N = normalize(n);

    // Ray-plane intersection
    float dDotN = dot(ray.direction, N);

    // Parallel to the plane => no hit
    if (abs(dDotN) < EPS) return;

    // Backface culling: if we don't draw backfaces, reject hits on the back side
    // (Ray hits the front face when dDotN < 0 with outward normal N)
    if (!drawBackface && dDotN > 0.0f) return;

    float t = dot(c - ray.origin, N) / dDotN;

    // In front and closer than current best
    if (t <= EPS) return;
    if (t >= bestHit.distance) return;

    float3 p = ray.origin + t * ray.direction;

    // Inside circle test (distance from center within radius)
    float3 d = p - c;
    if (dot(d, d) > r * r) return;

    // Fill bestHit
    bestHit.distance = t;
    bestHit.position = p;
    bestHit.normal   = N;         // geometric normal
    bestHit.material = material;}


// Checks for an intersection between a ray and a cylinder aligned with the Y axis
// The cylinder center is given by cylinder.xyz, its radius is cylinder.w and its height is h
void intersectCylinderY(Ray ray, inout RayHit bestHit, Material material, float4 cylinder, float h)
{
    float3 c = cylinder.xyz;
    float  r = cylinder.w;

    float yMin = c.y - 0.5f * h;
    float yMax = c.y + 0.5f * h;

    // Side intersection with infinite cylinder in XZ 
    float ox = ray.origin.x - c.x;
    float oz = ray.origin.z - c.z;
    float dx = ray.direction.x;
    float dz = ray.direction.z;

    float a = dx * dx + dz * dz;

    // If a == 0, ray is parallel to cylinder axis => no side hit (caps may still hit)
    if (a > EPS)
    {
        float b = 2.0f * (ox * dx + oz * dz);
        float cc = ox * ox + oz * oz - r * r;

        float disc = b * b - 4.0f * a * cc;
        if (disc >= 0.0f)
        {
            float s = sqrt(disc);
            float inv2a = 1.0f / (2.0f * a);

            float t0 = (-b - s) * inv2a;
            float t1 = (-b + s) * inv2a;

            // Check candidates in ascending order (t0 is usually nearer)
            // Candidate 1
            if (t0 > EPS && t0 < bestHit.distance)
            {
                float y0 = ray.origin.y + t0 * ray.direction.y;
                if (y0 >= yMin && y0 <= yMax)
                {
                    float3 p0 = ray.origin + t0 * ray.direction;

                    bestHit.distance = t0;
                    bestHit.position = p0;
                    bestHit.normal   = normalize(float3(p0.x - c.x, 0.0f, p0.z - c.z));
                    bestHit.material = material;
                }
            }

            // Candidate 2
            if (t1 > EPS && t1 < bestHit.distance)
            {
                float y1 = ray.origin.y + t1 * ray.direction.y;
                if (y1 >= yMin && y1 <= yMax)
                {
                    float3 p1 = ray.origin + t1 * ray.direction;

                    bestHit.distance = t1;
                    bestHit.position = p1;
                    bestHit.normal   = normalize(float3(p1.x - c.x, 0.0f, p1.z - c.z));
                    bestHit.material = material;
                }
            }
        }
    }

    // Caps (top and bottom) using intersectCircle 
    // Top cap at y = yMax, outward normal +Y
    intersectCircle(
        ray, bestHit, material,
        float4(c.x, yMax, c.z, r),
        float3(0.0f, 1.0f, 0.0f),
        true // draw both sides so rays from inside also hit
    );

    // Bottom cap at y = yMin, outward normal -Y
    intersectCircle(
        ray, bestHit, material,
        float4(c.x, yMin, c.z, r),
        float3(0.0f, -1.0f, 0.0f),
        true
    );
}
