#version 440

/* 

TODO:


*/

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

Shape getClosestShapeExceptSelf(Ray ray, Shape self);

vec3 getPixelColor(Ray ray);

vec3 getSelfShadow(Ray ray, Shape sphere, vec3 initialColor);

vec3 getSphereSelfShadow(Ray ray, Shape sphere, vec3 lightPosition, vec3 initialColor);

vec3 getPlaneSelfShadow(Ray ray, Shape plane, vec3 lightPosition, vec3 initialColor);

float getSphereLightIntensity(Ray ray, Shape sphere, vec3 lightPosition);

float getPlaneLightIntensity(Ray ray, Shape plane, vec3 lightPosition);

Quaternion multiplyQuaternions(Quaternion a, Quaternion b);

Quaternion conjugate(Quaternion q);

Ray getRay(ivec2 pixel_coords, ivec2 screen_size);

float getSDF(Shape shape, vec3 point);

float copysign(float x, float y);

float getShadow(Ray ray, Shape shape, vec3 lightPosition);

vec3 getReflection(Ray ray, Shape shape);

Ray getReflectedRay(Ray ray, Shape shape);

vec3 getSphereReflectedRay(Ray ray, Shape sphere);

vec3 getPlaneReflectedRay(Ray ray);

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
    float maxIterations = 80;
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
            pixelColor = closestShape.color;         //  <= solid color
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
        
        // calculate shadow
        vec3 lightPosition = vec3(20, -30, 0);
        pixelColor *= getShadow(ray, closestShape, lightPosition);
        // calculate reflection
        pixelColor = (1 - closestShape.reflectivity) * pixelColor + closestShape.reflectivity * getReflection(ray, closestShape);
        // calculate self shadow
        pixelColor = getSelfShadow(ray, closestShape, pixelColor);
        
    }

    return pixelColor;
}

vec3 getSelfShadow(Ray ray, Shape shape, vec3 initialColor) {

    vec3 lightPosition = vec3(20, -30, 0);
    vec3 pixelColor = vec3(0.0);

    if (shape.type == 0) // Sphere
    {
        pixelColor = getSphereSelfShadow(ray, shape, lightPosition, initialColor);
    }
    else if (shape.type == 1) // Plane
    {
        pixelColor = getPlaneSelfShadow(ray, shape, lightPosition, initialColor);
    }

    return pixelColor;
}

vec3 getSphereSelfShadow(Ray ray, Shape sphere, vec3 lightPosition, vec3 initialColor) {

    vec3 lightColor = vec3(1, 1, 1);
    float lightIntensity = getSphereLightIntensity(ray, sphere, lightPosition);
    vec3 pixelColor = initialColor * lightColor * lightIntensity;

    return pixelColor;
}

vec3 getPlaneSelfShadow(Ray ray, Shape plane, vec3 lightPosition, vec3 initialColor) {

    vec3 lightColor = vec3(1, 1, 1);
    float lightIntensity = getPlaneLightIntensity(ray, plane, lightPosition);
    vec3 pixelColor = initialColor * lightColor * lightIntensity;

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
    vec3 planeNormal = normalize(vec3(0, -1, 0));
    float dotProduct = dot(planeNormal, lightDirection);
    if (dotProduct > 0)
    {
        lightIntensity = dotProduct;
    }
    else
    {
        lightIntensity = 0;
    }

    return lightIntensity * lightIntensity;
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

float getShadow(Ray ray, Shape shape, vec3 lightPosition){

    bool shadow = false;
    float totalDistance = 0;
    int iteration = 0;
    int maxIterations = 40;
    float maxDistance = 50.0;
    float dist;
    float smallestDistance = 1.0;
    Shape closestShape;
    ray.direction = normalize(lightPosition - ray.origin);
    ray.origin += ray.direction * 1;

    while (iteration < maxIterations && totalDistance < maxDistance && (length(ray.origin - lightPosition) > 0.01))
    {
        closestShape = getClosestShapeExceptSelf(ray, shape);

        dist = getSDF(closestShape, ray.origin);
        if (dist < smallestDistance)
        {
            smallestDistance = dist;
        }
        dist = min(dist, length(ray.origin - lightPosition));
        if (dist < 0.01)
        {
            shadow = true;
            smallestDistance = 0;
            break;
        }
        totalDistance += dist;
        ray.origin += ray.direction * dist;
        iteration++;
    }

    return min(smallestDistance, 1.0);
}

Shape getClosestShapeExceptSelf(Ray ray, Shape self) {

    float closest = 999999;
    float dist;
    Shape closestShape;
    for (int i = 0; i < sphereCount; i++)
    {
        Shape shape = unpackShape(i);
        if (shape.center == self.center && shape.radius == self.radius && shape.color == self.color && shape.type == self.type)
        {
            continue;
        }
        dist = getSDF(shape, ray.origin);
        if (dist < closest)
        {
            closest = dist;
            closestShape = shape;
        }
    }

    return closestShape;
}

vec3 getReflection(Ray ray, Shape shape) {

    vec3 reflectionColor = vec3(0.0);
    Ray reflection = getReflectedRay(ray, shape);

    vec3 lightPosition = vec3(20, -30, 0);

    // Ray march 
    float totalDistance = 0;
    int iteration = 0;
    int maxIterations = 40;
    float maxDistance = 50.0;
    float dist;
    float smallestDistance = 1.0;
    Shape closestShape;
    reflection.origin += reflection.direction * 1;

    while (iteration < maxIterations && totalDistance < maxDistance)
    {
        closestShape = getClosestShapeExceptSelf(reflection, shape);

        dist = getSDF(closestShape, reflection.origin);
        if (dist < smallestDistance)
        {
            smallestDistance = dist;
        }
        if (dist < 0.01)
        {
            reflectionColor = closestShape.color;
            // calculate self shadow
            reflectionColor = getSelfShadow(reflection, closestShape, reflectionColor);

            break;
        }
        totalDistance += dist;
        reflection.origin += reflection.direction * dist;
        iteration++;
    }

    return reflectionColor;
}

Ray getReflectedRay(Ray ray, Shape shape) {

    Ray reflectionDirection;
    reflectionDirection.origin = ray.origin;
    if (shape.type == 0) // Sphere
    {
        reflectionDirection.direction = getSphereReflectedRay(ray, shape);
    }
    else if (shape.type == 1) // Plane
    {
        reflectionDirection.direction = getPlaneReflectedRay(ray);
    }

    return reflectionDirection;
}

vec3 getSphereReflectedRay(Ray ray, Shape sphere) {

    vec3 reflectedRayDir;
    vec3 sphereNormal = normalize(ray.origin - sphere.center);
    reflectedRayDir = ray.direction - 2 * sphereNormal * dot(ray.direction, sphereNormal);

    return normalize(reflectedRayDir);
}

vec3 getPlaneReflectedRay(Ray ray) {

    vec3 reflectedRayDir = ray.direction;
    reflectedRayDir.y = -reflectedRayDir.y;

    return reflectedRayDir;
}

