import SwiftUI

extension Effect {
    static let morphMiniPlayer = Effect(
        id: "morph.mini-player",
        category: .morph,
        interaction: .tap,
        name: L("Mini Player Expand", "迷你播放器展开"),
        summary: L(
            "A docked now-playing bar grows into the full player, its artwork flying to centre stage.",
            "底部正在播放条生长为完整播放器，封面飞向舞台中央。"
        ),
        prompt: L(
            "A frosted 64 pt now-playing bar docked above the bottom edge shows 44 pt artwork, the track title, artist and play/next controls. Tapping it grows the bar's own material background into a floating full player (32 pt corners) while the artwork flies up and scales to 132 pt and the title glides into place beneath it — all matched elements on one spring (response ≈0.5 s, damping ≈0.82). The library behind recedes to 94%, blurs 4 pt and dims. The scrubber and transport controls rise out of a blur 60 ms apart. Pausing shrinks the artwork to 84% with a softer, shorter shadow; playing springs it back — the Apple Music tell. Dragging the player down follows the finger and, past 90 pt, collapses it back into the bar.",
            "一条高 64 pt 的磨砂“正在播放”条停靠在底部上方：44 pt 封面、歌名、歌手以及播放 / 下一首按钮。点击后，这条播放条自身的材质背景生长为悬浮的完整播放器（32 pt 圆角），封面向上飞起并放大到 132 pt，歌名滑到封面下方——所有共享元素由同一条弹簧（响应约 0.5 秒、阻尼约 0.82）驱动。背后的音乐库缩小到 94%、模糊 4 pt 并变暗。进度条与播放控制从模糊中依次浮现，间隔 60 毫秒。暂停时封面缩小到 84%，投影变得更短更柔；继续播放时再弹回原尺寸——这正是 Apple Music 的标志性细节。向下拖动播放器会跟手移动，超过 90 pt 即收回为播放条。"
        ),
        implementation: L(
            "Bar and full player are exclusive views sharing matchedGeometryEffect ids for the material background, artwork and title (applied before their frames so sizes interpolate); playing state drives the artwork scale and shadow; a DragGesture offsets the player and collapses past a threshold.",
            "播放条与完整播放器互斥显示，材质背景、封面与标题共享 matchedGeometryEffect ID（放在 frame 之前以便尺寸插值）；播放状态驱动封面缩放与投影；DragGesture 让播放器跟手下移，越过阈值即收起。"
        ),
        apis: ["matchedGeometryEffect", "@Namespace", "DragGesture", "contentTransition(.symbolEffect(.replace))", "regularMaterial"],
        tags: ["mini player", "now playing", "music", "expand", "迷你播放器", "正在播放", "音乐", "展开"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.82),
            .toggle("breathe", L("Pause shrinks artwork", "暂停时封面收缩"), default: true),
        ]
    ) { ctx in
        MiniPlayerDemo(ctx: ctx)
    }
}

private struct MiniTrack {
    static let title = L("Golden Hour", "黄金时刻")
    static let artist = L("Aurora Lane", "极光巷")
}

private struct MiniPlayerDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var expanded = false
    @State private var playing = true
    @State private var dragY: CGFloat = 0
    @State private var previewStep = 0

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

    var body: some View {
        ZStack(alignment: .bottom) {
            PlayerLibrary(language: ctx.language)
                .scaleEffect(expanded ? 0.94 : 1, anchor: .top)
                .blur(radius: expanded ? 4 : 0)
                .opacity(expanded ? 0.55 : 1)
                .allowsHitTesting(!expanded)
            if expanded {
                FullPlayer(ns: ns, playing: playing, shrink: ctx.bool("breathe"), language: ctx.language, onPlay: togglePlay, onCollapse: collapse)
                    .offset(y: dragY)
                    .gesture(dismissDrag)
                    .padding(10)
            } else {
                MiniBar(ns: ns, playing: playing, language: ctx.language, onPlay: togglePlay, onExpand: expand)
                    .padding(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5) { previewAdvance() }
    }

    private var dismissDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                let t = value.translation.height
                dragY = t > 0 ? t : rubberBand(t, limit: 20)
            }
            .onEnded { value in
                if value.translation.height > 90 || value.predictedEndTranslation.height > 220 {
                    collapse()
                } else {
                    withAnimation(spring) { dragY = 0 }
                }
            }
    }

    private func expand() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(spring) {
            dragY = 0
            expanded = true
        }
    }

    private func collapse() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(spring) {
            expanded = false
            dragY = 0
        }
    }

    private func togglePlay() {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) { playing.toggle() }
    }

    private func previewAdvance() {
        switch previewStep % 4 {
        case 0: expand()
        case 1, 2: togglePlay()
        default: collapse()
        }
        previewStep += 1
    }
}

private struct PlayerArtwork: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(LinearGradient(colors: [Palette.amber, Palette.coral, Palette.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: "sun.horizon.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white.opacity(0.9))
                    .scaleEffect(0.46)
            }
    }
}

private struct MiniBar: View {
    let ns: Namespace.ID
    let playing: Bool
    let language: AppLanguage
    let onPlay: () -> Void
    let onExpand: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PlayerArtwork(cornerRadius: 10)
                .matchedGeometryEffect(id: "art", in: ns)
                .frame(width: 44, height: 44)
                .shadow(color: Palette.coral.opacity(0.3), radius: 6, y: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(MiniTrack.title, language)
                    .font(.subheadline.weight(.semibold))
                    .matchedGeometryEffect(id: "title", in: ns)
                Text(MiniTrack.artist, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button(action: onPlay) {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            Image(systemName: "forward.fill")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 36)
        }
        .padding(.horizontal, 10)
        .frame(height: 64)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
                .matchedGeometryEffect(id: "bg", in: ns)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onExpand)
    }
}

private struct FullPlayer: View {
    let ns: Namespace.ID
    let playing: Bool
    let shrink: Bool
    let language: AppLanguage
    let onPlay: () -> Void
    let onCollapse: () -> Void
    @State private var appeared = false

    var body: some View {
        let artScale: CGFloat = (playing || !shrink) ? 1 : 0.84
        VStack(spacing: 12) {
            PlayerArtwork(cornerRadius: 18)
                .matchedGeometryEffect(id: "art", in: ns)
                .frame(width: 132, height: 132)
                .scaleEffect(artScale)
                .shadow(color: Palette.coral.opacity(artScale < 1 ? 0.2 : 0.45), radius: artScale < 1 ? 10 : 22, y: artScale < 1 ? 5 : 14)
                .onTapGesture(perform: onCollapse)
            VStack(spacing: 2) {
                Text(MiniTrack.title, language)
                    .font(.headline)
                    .matchedGeometryEffect(id: "title", in: ns)
                Text(MiniTrack.artist, language)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .modifier(PlayerReveal(visible: appeared, delay: 0.04))
            }
            scrubber
                .modifier(PlayerReveal(visible: appeared, delay: 0.1))
            controls
                .modifier(PlayerReveal(visible: appeared, delay: 0.16))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            Capsule()
                .fill(Color.primary.opacity(0.18))
                .frame(width: 36, height: 5)
                .padding(.top, 7)
        }
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.regularMaterial)
                .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.2), radius: 26, y: 12)
                .matchedGeometryEffect(id: "bg", in: ns)
        }
        .onAppear { appeared = true }
    }

    private var scrubber: some View {
        VStack(spacing: 4) {
            Capsule()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.7))
                        .frame(width: 96, height: 4)
                }
            HStack {
                Text(verbatim: "1:24")
                Spacer()
                Text(verbatim: "-2:05")
            }
            .font(.caption2.weight(.medium).monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 34) {
            Image(systemName: "backward.fill")
                .font(.title3)
            Button(action: onPlay) {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 30))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 40)
            }
            .buttonStyle(.plain)
            Image(systemName: "forward.fill")
                .font(.title3)
        }
    }
}

private struct PlayerReveal: ViewModifier {
    let visible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 10)
            .blur(radius: visible ? 0 : 5)
            .animation(visible ? .spring(response: 0.45, dampingFraction: 0.86).delay(delay) : .easeOut(duration: 0.1), value: visible)
    }
}

/// A "Recently played" album grid behind the player.
private struct PlayerLibrary: View {
    let language: AppLanguage

    private let albums: [(String, [Color])] = [
        ("music.note", [Palette.violet, Palette.indigo]),
        ("guitars.fill", [Palette.mint, Palette.sky]),
        ("pianokeys", [Palette.pink, Palette.coral]),
        ("headphones", [Palette.sky, Palette.blue]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language == .zh ? "最近播放" : "Recently Played")
                .font(.title3.weight(.bold))
            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<albums.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: albums[index].1, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 84)
                        .overlay {
                            Image(systemName: albums[index].0)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
