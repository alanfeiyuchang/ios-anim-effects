/**
 * `ShaderCanvas`: a WebGL fragment shader filling its box, the web stand-in for SwiftUI's
 * `.colorEffect` / `.layerEffect` / `.distortionEffect` with Metal (MotionLab/Shaders/Shaders.metal).
 *
 *   <ShaderCanvas width={280} height={200} fragment={GLSL}
 *                 uniforms={(t) => ({ u_strength: 0.6, u_touch: [x, y] })}
 *                 source={canvasElement} />
 *
 * The fragment shader (GLSL ES 1.0) gets
 *   uniform vec2  u_size;     // box size in canvas points (like Metal's `size`)
 *   uniform float u_time;     // seconds since mount
 *   uniform sampler2D u_tex;  // `source` (a 2D canvas you draw the layer into), if given
 *   varying vec2  v_uv;       // 0…1, origin top-left (like SwiftUI's `position / size`)
 * plus whatever `uniforms` returns each frame (number → float, [a,b] → vec2, [a,b,c] → vec3,
 * [a,b,c,d] → vec4). Metal's `layer.sample(p)` becomes `texture2D(u_tex, p / u_size)`.
 *
 * SwiftUI cannot hand a view's pixels to WebGL, so a `.layerEffect` port draws the layer's content
 * into a 2D canvas (`source`) first; call `markDirty()` from the ref after redrawing it.
 */
import { forwardRef, useEffect, useImperativeHandle, useRef, type CSSProperties } from "react";

export type UniformValue = number | [number, number] | [number, number, number] | [number, number, number, number];

export interface ShaderCanvasHandle {
  /** Kept for callers; `source` is re-uploaded every frame. */
  markDirty(): void;
}

const VERTEX = `
attribute vec2 a_pos;
varying vec2 v_uv;
void main() {
  v_uv = vec2(a_pos.x * 0.5 + 0.5, 0.5 - a_pos.y * 0.5);
  gl_Position = vec4(a_pos, 0.0, 1.0);
}`;

export const ShaderCanvas = forwardRef<
  ShaderCanvasHandle,
  {
    width: number;
    height: number;
    fragment: string;
    uniforms?: (time: number) => Record<string, UniformValue>;
    source?: HTMLCanvasElement | null;
    /** Stop the frame loop (e.g. a still state); the last frame stays. */
    paused?: boolean;
    /** Frames per second cap (previews use 30). */
    fps?: number;
    style?: CSSProperties;
  }
>(function ShaderCanvas({ width, height, fragment, uniforms, source, paused = false, fps, style }, ref) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const latest = useRef({ uniforms, source, paused, fps });
  latest.current = { uniforms, source, paused, fps };
  const dirty = useRef(true);
  useImperativeHandle(ref, () => ({ markDirty: () => (dirty.current = true) }), []);

  useEffect(() => {
    const el = canvas.current;
    if (!el) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2) * 2;
    el.width = Math.round(width * dpr);
    el.height = Math.round(height * dpr);
    const gl = el.getContext("webgl", { premultipliedAlpha: true, alpha: true, antialias: true });
    if (!gl) return;
    const compile = (type: number, src: string) => {
      const shader = gl.createShader(type)!;
      gl.shaderSource(shader, src);
      gl.compileShader(shader);
      if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.error("[ShaderCanvas]", gl.getShaderInfoLog(shader), src);
      }
      return shader;
    };
    const program = gl.createProgram()!;
    gl.attachShader(program, compile(gl.VERTEX_SHADER, VERTEX));
    const header = "precision highp float;\nuniform vec2 u_size;\nuniform float u_time;\nuniform sampler2D u_tex;\nvarying vec2 v_uv;\n";
    gl.attachShader(program, compile(gl.FRAGMENT_SHADER, fragment.includes("precision ") ? fragment : header + fragment));
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) console.error("[ShaderCanvas] link", gl.getProgramInfoLog(program));
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
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
    const locations = new Map<string, WebGLUniformLocation | null>();
    const loc = (name: string) => {
      if (!locations.has(name)) locations.set(name, gl.getUniformLocation(program, name));
      return locations.get(name)!;
    };
    let raf = 0;
    let last = 0;
    const start = performance.now();
    const frame = (now: number) => {
      raf = requestAnimationFrame(frame);
      const { uniforms: make, source: src, paused: stopped, fps: cap } = latest.current;
      if (stopped && last) return;
      if (cap && now - last < 1000 / cap - 1) return;
      last = now;
      const time = (now - start) / 1000;
      gl.viewport(0, 0, el.width, el.height);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);
      if (src) {
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, src);
        dirty.current = false;
      }
      gl.uniform2f(loc("u_size"), width, height);
      gl.uniform1f(loc("u_time"), time);
      gl.uniform1i(loc("u_tex"), 0);
      const values = make ? make(time) : {};
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
      // Free this run's objects but keep the context: StrictMode re-runs the effect on the same canvas,
      // and a lost context cannot be recovered by getContext().
      gl.deleteTexture(texture);
      gl.deleteBuffer(buffer);
      gl.deleteProgram(program);
    };
  }, [width, height, fragment]);

  return <canvas ref={canvas} style={{ width, height, display: "block", ...style }} />;
});
