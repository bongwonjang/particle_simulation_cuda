#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>
#include <iostream>
#include <thread>

#include "particle_system.h"
#include "shader.h"

const int N = 64;
const int NUM_PARTICLES = N * N;
const int WINDOW_WIDTH = 1920;
const int SIMULATION_BOX_WIDTH = WINDOW_WIDTH * 3;
const int WINDOW_HEIGHT = 1080;
const int SIMULATION_BOX_HEIGHT = WINDOW_HEIGHT * 3;
const float DELTA_TIME = 0.1f;

void framebuffer_size_callback(GLFWwindow* window, int width, int height);

int main()
{
    if(!glfwInit())
    {
        std::cerr << "Failed to initialize GLFW" << std::endl;
        return -1;
    }

    GLFWwindow* window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Hello World!", nullptr, nullptr);
    if(!window)
    {
        std::cerr << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if(glewInit() != GLEW_OK)
    {
        std::cerr << "Failed to initialize GLEW" << std::endl;
        return -1;
    }

    UpdateMethod method = CUDA;
    
    ParticleSystem particle_system(NUM_PARTICLES, SIMULATION_BOX_WIDTH, SIMULATION_BOX_HEIGHT, method);

    float time = 0.0f;
    while(!glfwWindowShouldClose(window))
    {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        time += DELTA_TIME;

        particle_system.update(DELTA_TIME);
        particle_system.render(time);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
}