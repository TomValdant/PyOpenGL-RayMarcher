#version 460

struct Sphere {
    vec3 center;
    float radius;
    vec3 color;
    float type;
    float reflectivity;
};

struct Camera {
    vec3 position;
    vec3 forwards;
    vec3 right;
    vec3 up;
};

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Quaternion {
    float w;
    vec3 v;
};


// input/output
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba32f, binding = 0) uniform image2D img_output;

//Scene data
uniform Camera viewer;
layout(rgba32f, binding = 1) readonly uniform image2D spheres;
uniform float sphereCount;


// Functions prototypes -------------------------------------------------------

Sphere unpackSphere(int index);

float getSphereSDF(Sphere sphere, vec3 point);

Sphere getClosestSphere(Ray ray);

vec3 getPixelColor(Ray ray);

vec3 getSelfShadow(Ray ray, Sphere sphere);

float getLightIntensity(Ray ray, Sphere sphere, vec3 lightPosition);

Quaternion multiplyQuaternions(Quaternion a, Quaternion b);

Quaternion conjugate(Quaternion q);

Ray getRay(ivec2 pixel_coords, ivec2 screen_size);

// ----------------------------------------------------------------------------

void main() {

    ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
    ivec2 screen_size = imageSize(img_output);

    Ray ray = getRay(pixel_coords, screen_size);

    vec3 pixel = vec3(0.0);

    pixel = getPixelColor(ray);

    

    imageStore(img_output, pixel_coords, vec4(pixel,1.0));
}


// Functions definitions ------------------------------------------------------

Sphere unpackSphere(int index) {

    Sphere sphere;
    vec4 attributeChunk = imageLoad(spheres, ivec2(0,index));
    sphere.center = attributeChunk.xyz;
    sphere.radius = attributeChunk.w;
    
    attributeChunk = imageLoad(spheres, ivec2(1,index));
    sphere.color = attributeChunk.xyz;
    sphere.type = attributeChunk.w;

    attributeChunk = imageLoad(spheres, ivec2(2,index));
    sphere.reflectivity = attributeChunk.x;

    return sphere;
}

float getSphereSDF(Sphere sphere, vec3 point) {
    return length(sphere.center - point) - sphere.radius;
}

Sphere getClosestSphere(Ray ray) {

    float closest = 999999;
    float dist;
    Sphere closestSphere;
    for (int i = 0; i < sphereCount; i++)
    {
        Sphere sphere = unpackSphere(i);
        dist = getSphereSDF(sphere, ray.origin);
        if (dist < closest)
        {
            closest = dist;
            closestSphere = sphere;
        }
    }

    return closestSphere;
}

vec3 getPixelColor(Ray ray) {

    vec3 pixelColor = vec3(0.0);

    float totalDistance = 0 ;
    float iteration = 0;
    float maxIterations = 40;
    float maxDistance = 100;
    float dist;
    Sphere closestSphere;
    bool hit = false;

    while (iteration < maxIterations && totalDistance < maxDistance)
    {
        closestSphere = getClosestSphere(ray);
        dist = getSphereSDF(closestSphere, ray.origin);
        if (dist < 0.01)
        {
            // pixelColor = closestSphere.color;         //  <= solid color
            // pixelColor.x = iteration / maxIterations; //  <= heat map
            hit = true;
            break;
        }
        totalDistance += dist;
        ray.origin += ray.direction * dist;
        iteration++;
    }

    if (hit)
    {
        pixelColor = getSelfShadow(ray, closestSphere);
    }

    return pixelColor;
}

vec3 getSelfShadow(Ray ray, Sphere sphere) {

    vec3 lightPosition = vec3(20, -30, 0);
    vec3 lightColor = vec3(1, 1, 1);
    float lightIntensity = getLightIntensity(ray, sphere, lightPosition);
    vec3 pixelColor = sphere.color * lightColor * lightIntensity;

    return pixelColor;
}

float getLightIntensity(Ray ray, Sphere sphere, vec3 lightPosition) {

    // Calculate cross product of sphere normal at ray.origin and light direction
    float lightIntensity = 0;
    vec3 lightDirection = normalize(lightPosition - ray.origin);
    vec3 sphereNormal = normalize(ray.origin - sphere.center);
    float dotProduct = dot(sphereNormal, lightDirection);
    if (dotProduct > 0)
    {
        lightIntensity = dotProduct;
    }
    else
    {
        lightIntensity = 0;
    }

    return lightIntensity;
}

Quaternion multiplyQuaternions(Quaternion a, Quaternion b) {

    Quaternion result;
    result.w = a.w * b.w - dot(a.v, b.v);
    result.v = a.w * b.v + b.w * a.v + cross(a.v, b.v);

    return result;
}

Quaternion conjugate(Quaternion q) {

    Quaternion result;
    result.w = q.w;
    result.v = -q.v;

    return result;
}

Ray getRay(ivec2 pixel_coords, ivec2 screen_size) {

    Ray ray;
    ray.origin = viewer.position;
    ray.direction = normalize(vec3(pixel_coords.x - screen_size.x / 2, screen_size.x / 2 - pixel_coords.y, screen_size.x / 2));

    // Calculate rotation quaternion
    float cosYaw = cos(viewer.forwards.x * 0.5);
    float sinYaw = sin(viewer.forwards.x * 0.5);
    float cosPitch = cos(viewer.forwards.y * 0.5);
    float sinPitch = sin(viewer.forwards.y * 0.5);

    Quaternion yaw = Quaternion(cosYaw, vec3(0, sinYaw, 0));
    Quaternion pitch = Quaternion(cosPitch, vec3(sinPitch, 0, 0));

    Quaternion resultQuat = multiplyQuaternions(yaw, pitch);
    
    Quaternion rayQuat = Quaternion(0, ray.direction);
    Quaternion rotatedRayQuat = multiplyQuaternions(multiplyQuaternions(resultQuat, rayQuat), conjugate(resultQuat));
    ray.direction = normalize(rotatedRayQuat.v);

    return ray;
}