#include <metal_stdlib>
using namespace metal;
using namespace raytracing;

struct BoundingBoxIntersection {
    bool accept [[accept_intersection]];
    float distance [[distance]];
};

typedef struct Sphere {
    packed_float3 center;
    float radius;
} Sphere;

constant float2 quadVertices[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertexShader(unsigned short vid [[vertex_id]]) {
    float2 position = quadVertices[vid];

    VertexOut out;
    out.position = float4(position, 0, 1);
    out.uv = position;

    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               acceleration_structure<> accelStructure [[buffer(0)]],
                               intersection_function_table<triangle_data> intersectionFunctionTable [[buffer(1)]],
                               device Sphere * sphereBuffer [[buffer(2)]]) {

    ray r;

    r.origin = float3(0, 0, 3);
    r.direction = float3(in.uv, -1);

    intersector<triangle_data> intersector;
    intersection_result<triangle_data> intersection;

    intersection = intersector.intersect(r, accelStructure, intersectionFunctionTable);

    if (intersection.type == intersection_type::bounding_box) {
        Sphere sphere = sphereBuffer[intersection.primitive_id];

        float3 intersectionPoint = (r.origin + r.direction * intersection.distance);
        float3 normal = normalize((intersectionPoint - sphere.center) / sphere.radius);
        float3 color = 0.5 * (normal + float3(1));

        return float4(color, 1);
    } else {
        float3 unitDir = normalize(r.direction);
        float t = 0.5 * (unitDir.y + 1.0);
        float3 col = (1.0 - t) * float3(1.0, 1.0, 1.0) + t * float3(0.5, 0.7, 1.0);
        return float4(col, 1.0);
    }
}

[[intersection(bounding_box)]]
BoundingBoxIntersection sphereIntersectionFunction(uint id [[primitive_id]],
                                                   float3 origin [[origin]],
                                                   float3 direction [[direction]],
                                                   float minDistance [[min_distance]],
                                                   float maxDistance [[max_distance]],
                                                   device Sphere* sphereBuffer [[buffer(0)]]) {
    BoundingBoxIntersection ret;

    float3 oc = origin - sphereBuffer[id].center;

    float a = dot(direction, direction);
    float b = 2 * dot(oc, direction);
    float c = dot(oc, oc) - sphereBuffer[id].radius * sphereBuffer[id].radius;

    float disc = b * b - 4 * a * c;

    if (disc <= 0.0) {
        ret.accept = false;
    } else {
        ret.distance = (-b - sqrt(disc)) / (2 * a);
        ret.accept = ret.distance >= minDistance && ret.distance <= maxDistance;
    }

    return ret;
}
