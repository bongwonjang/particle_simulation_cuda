CXX = g++
NVCC = nvcc
CXXFLAGS = -std=c++17 -Wall -Iinclude
NVCCFLAGS = -gencode arch=compute_86,code=sm_86 -Iinclude --disable-warnings
CUDA_PATH = /usr/local/cuda
LDFLAGS = -L$(CUDA_PATH)/lib64 -lcudart -lGL -lGLEW -lglfw

# Directories
SRC_DIR = src
BUILD_DIR = build

# Source files
CPP_SRCS = $(wildcard $(SRC_DIR)/*.cpp) main.cpp
CU_SRCS = $(wildcard $(SRC_DIR)/*.cu)

# Object files
CPP_OBJS = $(patsubst %.cpp, $(BUILD_DIR)/%.o, $(notdir $(CPP_SRCS)))
CU_OBJS = $(patsubst %.cu, $(BUILD_DIR)/%.o, $(notdir $(CU_SRCS)))

# Executable
TARGET = particle_simulation

# Rules
all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(CPP_OBJS) $(CU_OBJS)
	$(CXX) -o $@ $(CPP_OBJS) $(CU_OBJS) $(LDFLAGS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cu
	$(NVCC) $(NVCCFLAGS) -c $< -o $@

$(BUILD_DIR)/main.o: main.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)

.PHONY: all clean