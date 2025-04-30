#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>

float read_value_from_file(const char* path) {
    FILE* file = fopen(path, "r");
    if (!file) return 0.0f;

    float value;
    fscanf(file, "%f", &value);
    fclose(file);
    return value;
}

int main(void) {
    if (!glfwInit()) {
        fprintf(stderr, "Failed to initialize GLFW\n");
        return -1;
    }

    GLFWwindow* window = glfwCreateWindow(640, 480, "GLFW from MATLAB", NULL, NULL);
    if (!window) {
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);

    while (!glfwWindowShouldClose(window)) {
        float val = read_value_from_file("input.txt");  // File updated by MATLAB

        glClear(GL_COLOR_BUFFER_BIT);
        glBegin(GL_TRIANGLES);
            glColor3f(1.0f, 0.0f, 0.0f);
            glVertex2f(-0.5f, -0.5f + val);
            glColor3f(0.0f, 1.0f, 0.0f);
            glVertex2f(0.5f, -0.5f + val);
            glColor3f(0.0f, 0.0f, 1.0f);
            glVertex2f(0.0f,  0.5f + val);
        glEnd();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}
