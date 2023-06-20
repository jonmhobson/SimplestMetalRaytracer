#include <metal_stdlib>
using namespace metal;
using namespace raytracing;

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
                               intersection_function_table<triangle_data> intersectionFunctionTable) {

    ray r;

    r.origin = float3(0, 0, 3);
    r.direction = float3(in.uv, -1);

    intersector<triangle_data> intersector;
    intersection_result<triangle_data> intersection;

    intersection = intersector.intersect(r, accelStructure, intersectionFunctionTable);

    if (intersection.type == intersection_type::triangle) {
        return float4(intersection.triangle_barycentric_coord, 1, 1);
    } else {
        return float4(in.uv, 0, 1);
    }
}

[[intersection(triangle, triangle_data)]]
bool customIntersectionFunction(float2 barycentricCoords [[barycentric_coord]]) {
    float3 barycentric = float3(1.0 - barycentricCoords.x - barycentricCoords.y, barycentricCoords);
    float dist = length(float3(0.5) - barycentric);
    return dist > 0.5;
}
