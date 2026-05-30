// Implements an adjusted version of the Blinn-Phong lighting model
float3 blinnPhong(float3 n, float3 v, float3 l, float shininess, float3 albedo) {
    n = normalize(n);
    v = normalize(v);
    l = normalize(l);

    float3 h = normalize(l + v);

    // Diffuse = max(0, n·l) * albedo
    float ndotl = max(0.0f, dot(n, l));
    float3 diffuse = ndotl * albedo;

    // Specular = max(0, n·h)^shininess * 0.4
    float ndoth = max(0.0f, dot(n, h));
    float spec = pow(ndoth, shininess) * 0.4f;

    return diffuse + spec;
}

// Reflects the given ray from the given hit point
void reflectRay(inout Ray ray, RayHit hit) {
    // Standard reflection formula
    ray.direction = normalize(reflect(ray.direction, hit.normal)); 

    // Offset the origin to avoid "Surface Acne"
    ray.origin = hit.position + hit.normal * EPS; 

    // Multiply energy by the specular coefficient
    ray.energy *= hit.material.specular;
}

// Refracts the given ray from the given hit point
void refractRay(inout Ray ray, RayHit hit) {
    float3 I = normalize(ray.direction);
    float3 N = normalize(hit.normal);

    // Indices of refraction:
    // air = 1.0, material = hit.material.refractiveIndex
    float etaI = 1.0f;
    float etaT = hit.material.refractiveIndex;

    // Figure out if we are entering or exiting.
    // If the ray is on the same side as the normal (dot > 0), we are inside -> exiting:
    // flip normal and swap indices.
    float cosi = dot(I, N);
    if (cosi > 0.0f) {
        N = -N;
        float tmp = etaI; etaI = etaT; etaT = tmp;
        cosi = dot(I, N); // recompute (now should be <= 0)
    }

    // Use cos(theta_i) as positive value
    float c1 = clamp(-cosi, 0.0f, 1.0f);
    float eta = etaI / etaT;

    // Snell's law term: k = 1 - eta^2 (1 - cos^2)
    float k = 1.0f - eta * eta * (1.0f - c1 * c1);
    float c2 = sqrt(k);

    float3 T;
    if (k < 0.0f) {
        // Total internal reflection -> reflect instead
        T = normalize(reflect(I, N));
    }
    else {
        // Refracted direction
        T = normalize(eta * I + (eta * c1 - c2) * N);
    }

    // Update ray (energy stays unchanged)
    ray.direction = T;
    ray.origin    = hit.position + T * EPS; // or + N*EPS; both avoid self-intersection
}

// Samples the _SkyboxTexture at a given direction vector
float3 sampleSkybox(float3 direction) {
    float theta = acos(direction.y) / -PI;
    float phi = atan2(direction.x, -direction.z) / -PI * 0.5f;
    return _SkyboxTexture.SampleLevel(sampler_SkyboxTexture, float2(phi, theta), 0).xyz;
}