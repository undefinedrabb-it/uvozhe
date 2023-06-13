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
const VertexAttribute = .{
    .position = 0,
    .color = 1,
};

const VertexAttributeCount = .{
    .position = 3,
    .color = 3,
};
const VertexT = f32;

const Vertex = struct {
    position: [VertexAttributeCount.position]VertexT,
    color: [VertexAttributeCount.color]VertexT,
};

const VertexAttributeByte = .{
    .position = 3 * @sizeOf(VertexT),
    .color = 3 * @sizeOf(VertexT),
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

var vao: ?zgl.VertexArray = undefined;
var vbo: ?zgl.Buffer = undefined;
var ebo: ?zgl.Buffer = undefined;

fn render() void {
    zgl.clearColor(0.2, 0.3, 0.3, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);
}

fn createShaderProgram() zgl.Program {
    const vertexShader = zgl.createShader(zgl.ShaderType.vertex);
    const vertexFiles = .{@embedFile("shaders/vert.glsl")};
    zgl.shaderSource(vertexShader, vertexFiles.len, &vertexFiles);
    zgl.compileShader(vertexShader);
    defer zgl.deleteShader(vertexShader);

    const fragmentShader = zgl.createShader(zgl.ShaderType.fragment);
    const fragFiles = .{@embedFile("shaders/frag.glsl")};
    zgl.shaderSource(fragmentShader, fragFiles.len, &fragFiles);
    zgl.compileShader(fragmentShader);
    defer zgl.deleteShader(fragmentShader);

    const shaderProgram = zgl.createProgram();
    zgl.attachShader(shaderProgram, vertexShader);
    zgl.attachShader(shaderProgram, fragmentShader);
    zgl.linkProgram(shaderProgram);
    return shaderProgram;
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(WIDTH, HEIGHT, "Uvozhe!", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 5,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();
    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    zgl.viewport(0, 0, WIDTH, HEIGHT);

    glfw.Window.setFramebufferSizeCallback(window, resize);

    vao = zgl.genVertexArray();
    zgl.bindVertexArray(vao.?);
    defer zgl.deleteVertexArray(vao.?);

    vbo = zgl.genBuffer();
    zgl.bindBuffer(vbo.?, zgl.BufferTarget.array_buffer);
    zgl.bufferData(zgl.BufferTarget.array_buffer, Vertex, &vertices, zgl.BufferUsage.static_draw);
    defer zgl.deleteBuffer(vbo.?);

    ebo = zgl.genBuffer();
    zgl.bindBuffer(ebo.?, zgl.BufferTarget.element_array_buffer);
    zgl.bufferData(zgl.BufferTarget.element_array_buffer, u32, &indeces, zgl.BufferUsage.static_draw);

    zgl.vertexAttribPointer(
        VertexAttribute.position,
        vertices.len,
        zgl.Type.float,
        false,
        @sizeOf(Vertex),
        @offsetOf(Vertex, "position"),
    );
    zgl.vertexAttribPointer(
        VertexAttribute.color,
        vertices.len,
        zgl.Type.float,
        false,
        @sizeOf(Vertex),
        @offsetOf(Vertex, "color"),
    );

    zgl.enableVertexAttribArray(VertexAttribute.position);
    zgl.enableVertexAttribArray(VertexAttribute.color);

    const shaderProgram = createShaderProgram();
    defer zgl.deleteProgram(shaderProgram);
    zgl.useProgram(shaderProgram);
    zgl.uniform2f(zgl.getUniformLocation(shaderProgram, "resolution"), HEIGHT, WIDTH);

    zgl.enable(zgl.Capabilities.blend);
    zgl.blendFunc(zgl.BlendFactor.src_alpha, zgl.BlendFactor.one_minus_src_alpha);

    // zgl.polygonMode(zgl.CullMode.front_and_back, zgl.DrawMode.line);
    // Wait for the user to close the window.
    glfw.Window.setKeyCallback(window, proceessInput);
    while (!window.shouldClose()) {
        render();

        zgl.useProgram(shaderProgram);
        zgl.bindVertexArray(vao.?);
        zgl.bindBuffer(ebo.?, zgl.BufferTarget.element_array_buffer);
        zgl.drawElements(zgl.PrimitiveType.triangles, indeces.len, zgl.ElementType.u32, 0);

        glfw.pollEvents();
        window.swapBuffers();
    }
}
