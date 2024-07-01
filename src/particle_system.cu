#include "particle_system.h"
#include <cuda_runtime.h>
#include <iostream>
#include <cmath>
#include <random>

__global__ void assignParticlesToCells(Particle* particles, int* cell_start, int* cell_end, int* cell_particles, unsigned int num_particles, int GRID_SIZE, float simulation_box_width, float simulation_box_height);
__device__ void handleBoundaryCollision(Particle& p, float radius, float top_boundary, float bottom_boundary, float left_boundary, float right_boundary);
__global__ void updateParticlesKernel(Particle* particles, Particle* new_particles, float radius, unsigned int num_particles, float delta_time, float top_boundary, float bottom_boundary, float left_boundary, float right_boundary);
// ---

void updateParticlesCUDA(Particle* particles, Particle* new_particles, int* cell_start, int* cell_end, int* cell_particles, float radius, float GRID_SIZE, unsigned int num_particles, float delta_time, float simulation_box_width, float simulation_box_height);
// ---

ParticleSystem::ParticleSystem(unsigned int num_particles, int simulation_box_width, int simulation_box_height, UpdateMethod update_method) 
    : num_particles(num_particles), simulation_box_width(simulation_box_width), simulation_box_height(simulation_box_height), update_method(update_method)
{
    particles.resize(num_particles);
    
    initParticles();
    initGL();
    if (update_method == CUDA)
        initCUDA();

    shader = new Shader("./shaders/vertex_shader.glsl", "./shaders/fragment_shader.glsl");

    glEnable(GL_PROGRAM_POINT_SIZE);
    glEnable(GL_POINT_SPRITE);
}

ParticleSystem::~ParticleSystem()
{
    if (update_method == CUDA)
        cudaGraphicsUnregisterResource(cudaVBO);

    glDeleteBuffers(1, &VBO);
    glDeleteVertexArrays(1, &VAO);
    delete shader;
    glDisable(GL_PROGRAM_POINT_SIZE);
    glDisable(GL_POINT_SPRITE);
}

void ParticleSystem::initParticles()
{
    // check if num_particles is sqaure.
    unsigned int side_length = static_cast<unsigned int>(std::sqrt(num_particles));
    if (side_length * side_length != num_particles)
    {
        std::cerr << "Number of particles must be a perfect square!" << std::endl;
        exit(EXIT_FAILURE);
    }

    float x_gl_res = 0.8f; // Change the variable name
    float y_gl_res = 0.8f; // Change the variable name

    float start_x = -x_gl_res * simulation_box_width / 2.0f;    // 1280 >> (-0.5 : 0.5) -> (-320 : 320)
    float start_y = -y_gl_res * simulation_box_height / 2.0f;   //  720 >> (-0.5 : 0.5) -> (-180 : 180)
    float step_x = (simulation_box_width / 2.0f) / side_length * (x_gl_res / 0.5f);
    float step_y = (simulation_box_height / 2.0f) / side_length * (y_gl_res / 0.5f);

    std::default_random_engine generator;
    std::uniform_real_distribution<float> distribution(-2.0f, 2.0f);

    for (unsigned int i = 0; i < side_length; i++)
    {
        for (unsigned int j = 0; j < side_length; j++)
        {
            unsigned int index = i * side_length + j;
            float x = start_x + i * step_x;
            float y = start_y + j * step_y;

            float noise_x = distribution(generator);
            float noise_y = distribution(generator);

            particles[index].position = glm::vec3(x + noise_x, y + noise_y, 0.0f);
            particles[index].velocity = glm::vec3(0.0f, 0.0f, 0.0f);
            particles[index].life = 1.0f;
        }
    }

}

void ParticleSystem::initGL()
{
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);

    glBindVertexArray(VAO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, num_particles * sizeof(Particle), particles.data(), GL_DYNAMIC_DRAW);

    // vertex positions
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Particle), (void*)0);

    glBindVertexArray(0);
}

void ParticleSystem::initCUDA()
{
    cudaGraphicsGLRegisterBuffer(&cudaVBO, VBO, cudaGraphicsMapFlagsWriteDiscard);
    cudaMalloc((void**)&d_new_particles, num_particles * sizeof(Particle));

    cudaMalloc((void**)&d_cell_start, GRID_SIZE * GRID_SIZE * sizeof(int));
    cudaMalloc((void**)&d_cell_end, GRID_SIZE * GRID_SIZE * sizeof(int));
    cudaMalloc((void**)&d_cell_particles, num_particles * sizeof(int));
}

void ParticleSystem::update(float delta_time)
{
    if(update_method == CUDA)
        updateCUDA(delta_time);
    else
        updateCPU(delta_time);
}

void ParticleSystem::updateCPU(float delta_time)
{
    // update something
    glm::vec3 gravity(0.0f, -9.8f, 0.0f);

    for (unsigned int i = 0; i < num_particles; i++)
    {
        for (unsigned int j = i + 1; j < num_particles; j++)
        {
            glm::vec3 delta = particles[j].position - particles[i].position;
            float distance = glm::length(delta);
            
            // collision detected
            if (distance < 2 * radius)
            {
                glm::vec3 normal = glm::normalize(delta);
                glm::vec3 relative_velocity = particles[j].velocity - particles[i].velocity;
                float velocity_along_normal = glm::dot(relative_velocity, normal);
                
                // collision is detected but particles are moving apart
                if(velocity_along_normal > 0)
                    continue;

                float restitution = 0.9f;
                float impulse_magnitude = -1.0f * (1 + restitution) * velocity_along_normal / 2.0f;

                glm::vec3 impulse = impulse_magnitude * normal;
                particles[i].velocity -= impulse;
                particles[j].velocity += impulse;

                float overlap = 2 * radius - distance;
                particles[i].position -= normal * overlap / 2.0f;
                particles[j].position += normal * overlap / 2.0f;
            }
        }
    }

    float top_boundary      = 1.0f * simulation_box_height / 2.0f;
    float bottom_boundary   = -1.0f * simulation_box_height / 2.0f;
    float left_boundary     = -1.0f * simulation_box_width / 2.0f;
    float right_boundary    = 1.0f * simulation_box_width / 2.0f;
        
    for (auto& p : particles)
    {
        p.velocity += gravity * delta_time;
        p.position += p.velocity * delta_time;
        p.life -= delta_time;

        if (p.position.y + radius > top_boundary)
        {
            p.position.y = top_boundary - radius;
            p.velocity.y *= -0.9f;
        }
        if (p.position.y - radius < bottom_boundary)
        {
            p.position.y = bottom_boundary + radius;
            p.velocity.y *= -0.9f;
        }        
        if (p.position.x - radius < left_boundary)
        {
            p.position.x = left_boundary + radius;
            p.velocity.x *= -0.9f;
        }
        if (p.position.x + radius > right_boundary)
        {
            p.position.x = right_boundary - radius;
            p.velocity.x *= -0.9f;
        }
    }

    // update vbo
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferSubData(GL_ARRAY_BUFFER, 0, num_particles * sizeof(Particle), particles.data());
}

void ParticleSystem::updateCUDA(float delta_time)
{
    Particle* d_particles;
    size_t num_bytes;

    // map vbo
    cudaGraphicsMapResources(1, &cudaVBO, 0);
    cudaGraphicsResourceGetMappedPointer((void**)&d_particles, &num_bytes, cudaVBO);

    // update something and vbo
    updateParticlesCUDA(d_particles, d_new_particles, d_cell_start, d_cell_end, d_cell_particles, radius, GRID_SIZE, num_particles, delta_time, simulation_box_width, simulation_box_height);

    // unmap vbo
    cudaGraphicsUnmapResources(1, &cudaVBO, 0);
}

void ParticleSystem::render(float time)
{
    shader->use();
    shader->setInt("simulation_box_width", simulation_box_width);
    shader->setInt("simulation_box_height", simulation_box_height);
    shader->setFloat("time", time);

    glBindVertexArray(VAO);
    glDrawArrays(GL_POINTS, 0, num_particles);
    glBindVertexArray(0);
}

__global__ void assignParticlesToCells(Particle* particles, int* cell_start, int* cell_end, int* cell_particles, unsigned int num_particles, int GRID_SIZE, float simulation_box_width, float simulation_box_height)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx >= num_particles)
        return;

    Particle& p = particles[idx];
    int cellX = int((p.position.x + simulation_box_width / 2.0f) / GRID_SIZE);
    int cellY = int((p.position.y + simulation_box_height / 2.0f) / GRID_SIZE);

    int cell_idx = cellY * GRID_SIZE + cellX;

    atomicMin(&cell_start[cell_idx], idx);
    atomicMax(&cell_start[cell_idx], idx);

    cell_particles[idx] = cell_idx;
}

__device__ void handleBoundaryCollision(Particle& p, float radius, float top_boundary, float bottom_boundary, float left_boundary, float right_boundary)
{
    if (p.position.y + radius > top_boundary)
    {
        p.position.y = top_boundary - radius;
        p.velocity.y *= -0.9f;
    }
    if (p.position.y - radius < bottom_boundary)
    {
        p.position.y = bottom_boundary + radius;
        p.velocity.y *= -0.9f;
    }
    if (p.position.x + radius > right_boundary)
    {
        p.position.x = right_boundary - radius;
        p.velocity.x *= -0.9f;
    }
    if (p.position.x - radius < left_boundary)
    {
        p.position.x = left_boundary + radius;
        p.velocity.x *= -0.9f;
    }
}

__global__ void updateParticlesKernel(Particle* particles, Particle* new_particles, float radius, unsigned int num_particles, float delta_time, float top_boundary, float bottom_boundary, float left_boundary, float right_boundary)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= num_particles) return;

    new_particles[idx] = particles[idx];
    Particle& p = particles[idx];
    
    // Handle particle collisions
    for (unsigned int j = 0; j < num_particles; j++)
    {
        if (j == idx)
            continue;
        
        Particle& q = particles[j];
        glm::vec3 delta = q.position - p.position;
        float distance = glm::length(delta);

        // collision detected
        if (distance < 2 * radius)
        {
            glm::vec3 normal = glm::normalize(delta);
            glm::vec3 relative_velocity = q.velocity - p.velocity;
            float velocity_along_normal = glm::dot(relative_velocity, normal);
            if (velocity_along_normal > 0)
                continue;
            
            float restitution = 1.0f;
            float impulse_magnitude = -1.0f * (1.0f + restitution) * velocity_along_normal / 2.0f;

            glm::vec3 impulse = impulse_magnitude * normal;
            new_particles[idx].velocity -= impulse;
            new_particles[idx].velocity *= 0.99f;
            
            float overlap = 2 * radius - distance;
            new_particles[idx].position -= normal * overlap / 2.0f;
        }
    }

    // Apply gravity and wall collision
    glm::vec3 gravity(0.0f, -0.98f * 0.5f, 0.0f);
    new_particles[idx].velocity += gravity * delta_time;
    new_particles[idx].position += new_particles[idx].velocity * delta_time;
    new_particles[idx].life -= delta_time;

    handleBoundaryCollision(new_particles[idx], radius, top_boundary, bottom_boundary, left_boundary, right_boundary);
}

void updateParticlesCUDA(Particle* particles, 
                        Particle* new_particles,
                        int* cell_start, 
                        int* cell_end, 
                        int* cell_particles, 
                        float radius, 
                        float GRID_SIZE,
                        unsigned int num_particles, 
                        float delta_time, 
                        float simulation_box_width, 
                        float simulation_box_height)
{
    // Boundary
    float top_boundary      = 1.0f * simulation_box_height / 2.0f;
    float bottom_boundary   = -1.0f * simulation_box_height / 2.0f;
    float left_boundary     = -1.0f * simulation_box_width / 2.0f;
    float right_boundary    = 1.0f * simulation_box_width / 2.0f;

    cudaMemset(cell_start, -1, GRID_SIZE * GRID_SIZE * sizeof(int));
    cudaMemset(cell_end, -1, GRID_SIZE * GRID_SIZE * sizeof(int));

    int threadsPerBlock = 256;
    int blocksPerGrid = (num_particles + threadsPerBlock - 1) / threadsPerBlock;

    assignParticlesToCells<<<blocksPerGrid, threadsPerBlock>>>(particles, cell_start, cell_end, cell_particles, num_particles, GRID_SIZE, simulation_box_width, simulation_box_height);
    cudaDeviceSynchronize();

    updateParticlesKernel<<<blocksPerGrid, threadsPerBlock>>>(particles, new_particles, radius, num_particles, delta_time, top_boundary, bottom_boundary, left_boundary, right_boundary);
    cudaMemcpy(particles, new_particles, num_particles * sizeof(Particle), cudaMemcpyDeviceToDevice);
}