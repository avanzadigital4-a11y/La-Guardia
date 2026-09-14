shader_type spatial;
// Superficie estilo PS1: iluminacion por vertice, sin specular y con el
// vertice "encajado" a una grilla de baja resolucion en espacio de clip,
// que es lo que produce el temblor caracteristico de la consola.
render_mode skip_vertex_transform, vertex_lighting, specular_disabled, diffuse_lambert, cull_back;

uniform vec3 albedo_color : source_color = vec3(0.3, 0.3, 0.32);
uniform vec2 snap_resolution = vec2(160.0, 120.0);
uniform float snap_strength : hint_range(0.0, 1.0) = 0.8;
uniform float emission_amount : hint_range(0.0, 4.0) = 0.0;

void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	vec4 clip = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	if (clip.w > 0.0) {
		vec3 ndc = clip.xyz / clip.w;
		vec2 snapped = round(ndc.xy * snap_resolution) / snap_resolution;
		ndc.xy = mix(ndc.xy, snapped, snap_strength);
		clip = vec4(ndc * clip.w, clip.w);
		vec4 view = INV_PROJECTION_MATRIX * clip;
		VERTEX = view.xyz / view.w;
	}
}

void fragment() {
	ALBEDO = albedo_color;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = albedo_color * emission_amount;
}
