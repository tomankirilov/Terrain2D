shader_type canvas_item;

const int TILES = 4;
const float STEP = 1./float(TILES);

uniform sampler2D tex;
uniform int index_x : hint_range(0,3,1) = 0;
uniform int index_y : hint_range(0,3,1) = 0;


void vertex() {
	
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR = texture(tex, ((UV * STEP) + vec2(float(index_x) * STEP,float(index_y) * STEP)));
	// Called for every pixel the material is visible on.
}

void light() {
	
	// Called for every pixel for every light affecting the material.
}
