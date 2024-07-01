#ifndef PARTICLE_H
#define PARTICLE_H

#include <glm/glm.hpp>

struct Particle
{
    glm::vec3 position;
    glm::vec3 velocity;
    float life;

    Particle() : position(0.0f), velocity(0.0f), life(0.0f) {}
};


#endif