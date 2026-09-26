/**
 * `Shader`: the Shaders category's own stand-in for the kit's `ShaderCanvas` (same contract: a GLSL ES 1.0
 * fragment shader filling a `width × height` box with `u_size`, `u_time`, `u_tex`, `v_uv` and custom uniforms).
 *
 * Why not `ShaderCanvas`: under React StrictMode (the gallery) its effect runs twice on the same <canvas>; the
 * first cleanup calls `WEBGL_lose_context.loseContext()`, so the second run gets a lost context and every shader
 * fails to compile (info log `null`). Here each mount creates a fresh <canvas> element, so losing the old
 * context on cleanup is harmless. Also, `uniforms(time)` runs before the source texture is uploaded, so a demo
 * can redraw its layer canvas inside it with no frame of lag.
 */
import { useEffect, useRef, type CSSProperties } from "react";

export type Uniform = number | [number, number] | [number, number, number] | [number, number, number, number];

const VERTEX = `
attribute vec2 a_pos;
varying vec2 v_uv;
void main() {
  v_uv = vec2(a_pos.x * 0.5 + 0.5, 0.5 - a_pos.y * 0.5);
  gl_Position = vec4(a_pos, 0.0, 1.0);
}`;

const HEADER = "precision highp float;\nuniform vec2 u_size;\nuniform float u_time;\nuniform sampler2D u_tex;\nvarying vec2 v_uv;\n";

export function Shader({
  width,
  height,
  fragment,
  uniforms,
  source,
  fps,
  scale,
  style,
}: {
  width: number;
  height: number;
  fragment: string;
  /** Called every frame (before the source upload) with seconds since mount. */
  uniforms?: (time: number) => Record<string, Uniform>;
  source?: HTMLCanvasElement | null;
  fps?: number;
  /** Backing pixels per point (default: 2 × devicePixelRatio, capped at 3). */
  scale?: number;
  style?: CSSProperties;
}) {
  const host = useRef<HTMLDivElement>(null);
  const latest = useRef({ uniforms, source, fps });
  latest.current = { uniforms, source, fps };

  useEffect(() => {
    const box = host.current;
    if (!box) return;
    const el = document.createElement("canvas");
    el.style.width = `${width}px`;
    el.style.height = `${height}px`;
    el.style.display = "block";
    box.appendChild(el);
    const k = scale ?? Math.min(3, Math.max(2, (window.devicePixelRatio || 1) * 1.5));
    el.width = Math.round(width * k);
    el.height = Math.round(height * k);
    const gl = el.getContext("webgl", { premultipliedAlpha: true, alpha: true, antialias: false });
    if (!gl) return () => el.remove();
    const compile = (type: number, src: string) => {
      const sh = gl.createShader(type)!;
      gl.shaderSource(sh, src);
      gl.compileShader(sh);
      if (!gl.getShaderParameter(sh, gl.COMPILE_STATUS) && !gl.isContextLost()) console.error("[shaders]", gl.getShaderInfoLog(sh));
      return sh;
    };
    const program = gl.createProgram()!;
    gl.attachShader(program, compile(gl.VERTEX_SHADER, VERTEX));
    gl.attachShader(program, compile(gl.FRAGMENT_SHADER, HEADER + fragment));
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS) && !gl.isContextLost()) console.error("[shaders] link", gl.getProgramInfoLog(program));
    gl.useProgram(program);
    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]), gl.STATIC_DRAW);
    const pos = gl.getAttribLocation(program, "a_pos");
    gl.enableVertexAttribArray(pos);
    gl.vertexAttribPointer(pos, 2, gl.FLOAT, false, 0, 0);
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([0, 0, 0, 0]));
    const locs = new Map<string, WebGLUniformLocation | null>();
    const loc = (name: string) => {
      if (!locs.has(name)) locs.set(name, gl.getUniformLocation(program, name));
      return locs.get(name)!;
    };
    let raf = 0;
    let last = 0;
    const start = performance.now();
    const frame = (now: number) => {
      raf = requestAnimationFrame(frame);
      const { uniforms: make, source: src, fps: cap } = latest.current;
      if (cap && last && now - last < 1000 / cap - 1) return;
      last = now;
      const time = (now - start) / 1000;
      const values = make ? make(time) : {};
      gl.viewport(0, 0, el.width, el.height);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);
      if (src && src.width > 0) {
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, src);
      }
      gl.uniform2f(loc("u_size"), width, height);
      gl.uniform1f(loc("u_time"), time);
      gl.uniform1i(loc("u_tex"), 0);
      for (const [name, value] of Object.entries(values)) {
        const l = loc(name);
        if (!l) continue;
        if (typeof value === "number") gl.uniform1f(l, value);
        else if (value.length === 2) gl.uniform2f(l, value[0], value[1]);
        else if (value.length === 3) gl.uniform3f(l, value[0], value[1], value[2]);
        else gl.uniform4f(l, value[0], value[1], value[2], value[3]);
      }
      gl.drawArrays(gl.TRIANGLES, 0, 6);
    };
    raf = requestAnimationFrame(frame);
    return () => {
      cancelAnimationFrame(raf);
      gl.getExtension("WEBGL_lose_context")?.loseContext();
      el.remove();
    };
  }, [width, height, fragment, scale]);

  return <div ref={host} style={{ width, height, flexShrink: 0, ...style }} />;
}
