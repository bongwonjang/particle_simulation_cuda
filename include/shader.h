#ifndef SHADER_H
#define SHADER_H

#include <GL/glew.h>
#include <string>

class Shader
{
public:
    GLuint program;
    Shader(const char* vertexPath, const char* fragmentPath);
    void use();

    void setFloat(const std::string &name, float value) const;
    void setInt(const std::string &name, int value) const;

private:
    std::string readFile(const char* filePath);
    void checkCompileErrors(GLuint shader, std::string type);
};

#endif