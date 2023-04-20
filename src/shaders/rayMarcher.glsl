#version 460

struct Shape {
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

Shape unpackShape(int index);

float getSphereSDF(Shape sphere, vec3 point);

float getPlaneSDF(Shape plane, vec3 point);

Shape getClosestShape(Ray ray);

vec3 getPixelColor(Ray ray);

vec3 getSelfShadow(Ray ray, Shape sphere);

vec3 getSphereSelfShadow(Ray ray, Shape sphere, vec3 lightPosition);

vec3 getPlaneSelfShadow(Ray ray, Shape plane, vec3 lightPosition);

float getSphereLightIntensity(Ray ray, Shape sphere, vec3 lightPosition);

float getPlaneLightIntensity(Ray ray, Shape plane, vec3 lightPosition);

Quaternion multiplyQuaternions(Quaternion a, Quaternion b);

Quaternion conjugate(Quaternion q);

Ray getRay(ivec2 pixel_coords, ivec2 screen_size);

float getSDF(Shape shape, vec3 point);

float copysign(float x, float y);

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

Shape unpackShape(int index) {

    Shape shape;
    vec4 attributeChunk = imageLoad(spheres, ivec2(0,index));
    shape.center = attributeChunk.xyz;
    shape.radius = attributeChunk.w;
    
    attributeChunk = imageLoad(spheres, ivec2(1,index));
    shape.color = attributeChunk.xyz;
    shape.type = attributeChunk.w;

    attributeChunk = imageLoad(spheres, ivec2(2,index));
    shape.reflectivity = attributeChunk.x;

    return shape;
}

float getSDF(Shape shape, vec3 point) {

    float sdf;

    if (shape.type == 0) // Sphere
    {
        sdf = getSphereSDF(shape, point);
    }
    else if (shape.type == 1) // Plane
    {
        sdf = getPlaneSDF(shape, point);
    }

    return sdf;
}

float getSphereSDF(Shape sphere, vec3 point) {
    return length(sphere.center - point) - sphere.radius;
}

float getPlaneSDF(Shape plane, vec3 point) {
    float minx[2] = {point.x, plane.center.x};
    if (minx[0] > minx[1]) {
        minx[0] = minx[1];
        minx[1] = point.x;
    }
    float minz[2] = {point.z, plane.center.z};
    if (minz[0] > minz[1]) {
        minz[0] = minz[1];
        minz[1] = point.z;
    }

    float distx = max(minx[1] - minx[0] - plane.radius, 0.0); // maybe replace plane.radius by plae.width and plane.height in the future
    float distz = max(minz[1] - minz[0] - plane.radius, 0.0); // here too

    float hitx = point.x - copysign(distx, point.x - plane.center.x);
    float hitz = point.z - copysign(distz, point.z - plane.center.z);

    return sqrt(pow(point.x - hitx, 2) + pow(point.z - hitz, 2) + pow(point.y - plane.center.y, 2));
}

Shape getClosestShape(Ray ray) {

    float closest = 999999;
    float dist;
    Shape closestShape;
    for (int i = 0; i < sphereCount; i++)
    {
        Shape shape = unpackShape(i);
        dist = getSDF(shape, ray.origin);
        if (dist < closest)
        {
            closest = dist;
            closestShape = shape;
        }
    }

    return closestShape;
}

vec3 getPixelColor(Ray ray) {

    vec3 pixelColor = vec3(0.0);

    float totalDistance = 0 ;
    float iteration = 0;
    float maxIterations = 40;
    float maxDistance = 100;
    float dist;
    Shape closestShape;
    bool hit = false;

    while (iteration < maxIterations && totalDistance < maxDistance)
    {
        closestShape = getClosestShape(ray);
        dist = getSDF(closestShape, ray.origin);
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
        pixelColor = getSelfShadow(ray, closestShape);
    }

    return pixelColor;
}

vec3 getSelfShadow(Ray ray, Shape shape) {

    vec3 lightPosition = vec3(20, -30, 0);
    vec3 pixelColor = vec3(0.0);

    if (shape.type == 0) // Sphere
    {
        pixelColor = getSphereSelfShadow(ray, shape, lightPosition);
    }
    else if (shape.type == 1) // Plane
    {
        pixelColor = getPlaneSelfShadow(ray, shape, lightPosition);
    }

    return pixelColor;
}

vec3 getSphereSelfShadow(Ray ray, Shape sphere, vec3 lightPosition) {

    vec3 lightColor = vec3(1, 1, 1);
    float lightIntensity = getSphereLightIntensity(ray, sphere, lightPosition);
    vec3 pixelColor = sphere.color * lightColor * lightIntensity;

    return pixelColor;
}

vec3 getPlaneSelfShadow(Ray ray, Shape plane, vec3 lightPosition) {

    vec3 lightColor = vec3(1, 1, 1);
    float lightIntensity = getPlaneLightIntensity(ray, plane, lightPosition);
    vec3 pixelColor = plane.color * lightColor * lightIntensity;

    return pixelColor;
}

float getSphereLightIntensity(Ray ray, Shape sphere, vec3 lightPosition) {

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

float getPlaneLightIntensity(Ray ray, Shape plane, vec3 lightPosition) {

    // Calculate cross product of plane normal at ray.origin and light direction
    float lightIntensity = 0;
    vec3 lightDirection = normalize(lightPosition - ray.origin);
    vec3 planeNormal = normalize(vec3(0, 1, 0));
    float dotProduct = dot(planeNormal, lightDirection);
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

float copysign(float a, float b) {
    return abs(a) * sign(b);
}