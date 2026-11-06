shader_type spatial;

uniform vec4 albedo : source_color = vec4(0.48, 0.77, 0.50, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
	SPECULAR = 0.1;
	// คำนวณ Normal จากหน้าสามเหลี่ยมแต่ละหน้า ทำให้เห็นเหลี่ยมชัด
	NORMAL = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}