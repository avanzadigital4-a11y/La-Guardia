shader_type spatial;
// Superficie estilo PS1: iluminacion por vertice, sin specular y con el
// vertice "encajado" a una grilla de baja resolucion en espacio de clip,
// que es lo que produce el temblor caracteristico de la consola.
render_mode skip_vertex_transform, vertex_lighting, specular_disabled, diffuse_lambert, cull_back;

uniform vec3 albedo_color : source_color = vec3(0.3, 0.3, 0.32);
// Textura en escala de grises que multiplica al color. NEAREST y sin mipmaps
// a proposito: el aliasing es parte de la estetica.
uniform sampler2D albedo_tex : filter_nearest, repeat_enable, hint_default_white;
uniform bool use_tex = false;
// Cuantas veces se repite la textura por metro de mundo.
uniform float tex_scale = 0.5;
uniform vec2 snap_resolution = vec2(160.0, 120.0);
uniform float snap_strength : hint_range(0.0, 1.0) = 0.8;
uniform float emission_amount : hint_range(0.0, 4.0) = 0.0;

// Posicion y normal en espacio de mundo, para el mapeo triplanar. Se calculan
// antes de aplastar el vertice contra la grilla: si no, la textura tiembla
// junto con la geometria y marea.
varying vec3 mundo_pos;
varying vec3 mundo_nrm;

void vertex() {
	mundo_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	mundo_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

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

// Triplanar: la estacion son cajas de tamanos muy distintos generadas por
// codigo y sin UV desplegadas. Mapear por coordenada de mundo evita tener que
// desplegar nada y mantiene el mismo tamano de textura en toda la estacion,
// que es lo que hace que una pared de 8 metros y una de 3 se lean iguales.
float mancha(vec3 p, vec3 n) {
	vec3 peso = abs(n);
	peso /= max(peso.x + peso.y + peso.z, 0.0001);
	float x = texture(albedo_tex, p.zy * tex_scale).r;
	float y = texture(albedo_tex, p.xz * tex_scale).r;
	float z = texture(albedo_tex, p.xy * tex_scale).r;
	return x * peso.x + y * peso.y + z * peso.z;
}

void fragment() {
	vec3 color = albedo_color;
	if (use_tex) {
		color *= mancha(mundo_pos, normalize(mundo_nrm));
	}
	ALBEDO = color;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = color * emission_amount;
}
