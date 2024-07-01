#ifndef PARTICLE_SYSTEM_H
#define PARTICLE_SYSTEM_H

#include <vector>
#include <GL/glew.h>
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>
#include "particle.h"
#include "shader.h"

enum UpdateMethod {
    CPU,
    CUDA
};

class ParticleSystem
{
public:
    ParticleSystem(unsigned int num_particles, int simulation_box_width, int simulation_box_height, UpdateMethod method = CPU);
    ~ParticleSystem();

    void update(float delta_time);
    void render(float time);

private:
    void initParticles();
    void initGL();
    void initCUDA();
    void updateCPU(float delta_time);
    void updateCUDA(float delta_time);
    
    float radius = 16.0f;
    unsigned int num_particles;
    int simulation_box_width;
    int simulation_box_height;
    std::vector<Particle> particles;

    GLuint VAO, VBO;
    cudaGraphicsResource* cudaVBO;

    UpdateMethod update_method;
    Shader* shader;

    // Particle information buffer
    Particle* d_new_particles;
    // Cell information buffer
    int GRID_SIZE = 32;
    int* d_cell_start;
    int* d_cell_end;
    int* d_cell_particles;
};

#endif