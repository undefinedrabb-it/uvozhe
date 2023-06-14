const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const gl = zgl.gl;

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

const WIDTH = 800;
const HEIGHT = 800;

fn resize(window: glfw.Window, width: u32, height: u32) void {
    _ = window;
    zgl.viewport(0, 0, width, height);
}

fn proceessInput(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
    _ = scancode;
    _ = mods;
    if (key == glfw.Key.escape and action == glfw.Action.press) {
        window.setShouldClose(true);
    }
}

const Vertex = struct {
    position: [3]f32,
    color: [3]f32,
};

const vertices = [_]Vertex{
    .{
        .position = .{ 0.5, -0.5, 0.0 },
        .color = .{ 0.0, 1.0, 0.0 },
    },
    .{
        .position = .{ 0.5, 0.5, 0.0 },
        .color = .{ 1.0, 0.0, 0.0 },
    },
    .{
        .position = .{ -0.5, 0.5, 0.0 },
        .color = .{ 0.0, 0.0, 0.0 },
    },
    .{
        .position = .{ -0.5, -0.5, 0.0 },
        .color = .{ 0.0, 0.0, 1.0 },
    },
};

const indeces = [_]u32{
    0, 1, 2,
    2, 3, 0,
};

const Shader = struct {
    vao: zgl.VertexArray,
    vbo: zgl.Buffer,
    ebo: zgl.Buffer,
    program: zgl.Program,
};

fn render(shader: Shader) void {
    zgl.clearColor(0.2, 0.3, 0.3, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);

    const timeValue = @floatCast(f32, glfw.getTime());
    const time = zgl.getUniformLocation(shader.program, "time");
    zgl.uniform1f(time, timeValue);

    zgl.useProgram(shader.program);
    zgl.bindVertexArray(shader.vao);
    zgl.bindBuffer(shader.ebo, zgl.BufferTarget.element_array_buffer);
    zgl.drawElements(
        zgl.PrimitiveType.triangles,
        indeces.len,
        zgl.ElementType.u32,
        0,
    );
}

fn createShaderProgram() zgl.Program {
    const vertexShader = zgl.createShader(zgl.ShaderType.vertex);
    const vertexFiles = .{@embedFile("shaders/vert.vert")};
    zgl.shaderSource(vertexShader, vertexFiles.len, &vertexFiles);
    zgl.compileShader(vertexShader);
    defer zgl.deleteShader(vertexShader);

    const fragmentShader = zgl.createShader(zgl.ShaderType.fragment);
    const fragmentFiles = .{@embedFile("shaders/frag.frag")};
    zgl.shaderSource(fragmentShader, fragmentFiles.len, &fragmentFiles);
    zgl.compileShader(fragmentShader);
    defer zgl.deleteShader(fragmentShader);

    const program = zgl.createProgram();
    zgl.attachShader(program, vertexShader);
    zgl.attachShader(program, fragmentShader);
    zgl.linkProgram(program);

    return program;
}

fn initGL() !void {
    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(
        WIDTH,
        HEIGHT,
        "Uvozhe!",
        null,
        null,
        .{
            .opengl_profile = .opengl_core_profile,
            .context_version_major = 4,
            .context_version_minor = 6,
        },
    ) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();
    glfw.makeContextCurrent(window);

    try initGL();
    glfw.Window.setFramebufferSizeCallback(window, resize);

    zgl.viewport(0, 0, WIDTH, HEIGHT);

    const vao = zgl.genVertexArray();
    zgl.bindVertexArray(vao);
    defer zgl.deleteVertexArray(vao);

    const vbo = zgl.genBuffer();
    zgl.bindBuffer(vbo, zgl.BufferTarget.array_buffer);
    zgl.bufferData(
        zgl.BufferTarget.array_buffer,
        Vertex,
        &vertices,
        zgl.BufferUsage.static_draw,
    );
    defer zgl.deleteBuffer(vbo);

    const ebo = zgl.genBuffer();
    zgl.bindBuffer(ebo, zgl.BufferTarget.element_array_buffer);
    zgl.bufferData(
        zgl.BufferTarget.element_array_buffer,
        u32,
        &indeces,
        zgl.BufferUsage.static_draw,
    );
    defer zgl.deleteBuffer(ebo);

    const shaderProgram = createShaderProgram();
    defer zgl.deleteProgram(shaderProgram);

    const shader = Shader{
        .vao = vao,
        .vbo = vbo,
        .ebo = ebo,
        .program = shaderProgram,
    };

    const aPos = zgl.getAttribLocation(shader.program, "aPos").?;
    zgl.vertexAttribPointer(
        aPos,
        vertices.len,
        zgl.Type.float,
        false,
        @sizeOf(Vertex),
        @offsetOf(Vertex, "position"),
    );
    zgl.enableVertexAttribArray(aPos);

    const aCol = zgl.getAttribLocation(shader.program, "aCol").?;
    zgl.vertexAttribPointer(
        aCol,
        vertices.len,
        zgl.Type.float,
        false,
        @sizeOf(Vertex),
        @offsetOf(Vertex, "color"),
    );
    zgl.enableVertexAttribArray(aCol);

    zgl.useProgram(shader.program);
    const resolution = zgl.getUniformLocation(shader.program, "resolution").?;
    zgl.uniform2f(resolution, HEIGHT, WIDTH);

    zgl.enable(zgl.Capabilities.blend);
    zgl.blendFunc(zgl.BlendFactor.src_alpha, zgl.BlendFactor.one_minus_src_alpha);

    // zgl.polygonMode(zgl.CullMode.front_and_back, zgl.DrawMode.line);
    glfw.Window.setKeyCallback(window, proceessInput);
    while (!window.shouldClose()) {
        render(shader);
        glfw.pollEvents();
        window.swapBuffers();
    }
}
