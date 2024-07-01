```
my_project/
├── CMakeLists.txt        # Build configuration file (if using CMake)
├── Makefile              # Optional: Alternative build configuration file (if using Make)
├── src/                  # Source files
│   ├── main.cpp          # Main application file
│   ├── app/              # Application-specific source files
│   │   ├── App.cpp
│   │   └── App.h
│   ├── utils/            # Utility source files
│   │   ├── Utils.cpp
│   │   └── Utils.h
│   ├── cuda/             # CUDA specific files
│   │   ├── kernel.cu
│   │   └── kernel.h
│   └── shaders/          # Shader source files
│       ├── vertex_shader.glsl
│       └── fragment_shader.glsl
├── include/              # Header files (can also be in src/)
│   ├── App.h
│   └── Utils.h
├── tests/                # Unit tests
│   ├── CMakeLists.txt
│   ├── main.cpp
│   └── test_app.cpp
├── lib/                  # External libraries
│   ├── SFML/
│   └── other_libs/
├── build/                # Build directory (usually created during build process)
│   └── (build artifacts)
├── docs/                 # Documentation
│   └── ...
├── examples/             # Example applications or usage
│   ├── example1.cpp
│   └── example2.cpp
└── README.md             # Project overview and setup instructions
```