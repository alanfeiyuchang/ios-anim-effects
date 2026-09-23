import SwiftUI

extension Effect {
    static let scrollInsertRemove = Effect(
        id: "scroll.insert-remove",
        category: .scroll,
        interaction: .tap,
        name: L("List Insert & Remove", "列表增删动画"),
        summary: L("Rows drop in at the top and slide away on delete while the list reflows smoothly.", "新行从顶部落入，删除时滑出，其余行平滑重排。"),
        prompt: L(
            "An inbox-style list of rounded rows sits under a header with a live count and a round gradient “+” button. Tapping + inserts a new row at the top: it drops in from above while fading up, and every existing row slides down to make room on the same spring (response ≈0.45 s, damping ≈0.8) so the whole list moves as one elastic body. Tapping a row's × removes it: the row slides out to the right and fades while the rows beneath glide up to close the gap. Alternative styles pop rows in from 70% scale or dissolve them through a 10 pt blur. The count ticks with a rolling numeric transition, and each action has a light haptic. Clear cause and effect, no jumps.",
            "收件箱式的圆角列表上方是带实时计数和圆形渐变「+」按钮的标题栏。点击 + 会在顶部插入一行：新行自上方落入并淡入，已有各行以同一弹簧（响应约 0.45 秒、阻尼约 0.8）向下让位，整个列表像一个有弹性的整体一起移动。点击某行的 × 将其删除：该行向右滑出并淡出，下方各行上移补齐空缺。另有样式可让新行从 70% 缩放弹出，或以 10 pt 模糊溶解消失。计数以滚动数字过渡跳变，每次操作都有轻触感。因果清晰，毫无跳变。"
        ),
        implementation: L(
            "Rows are an identifiable ForEach inside a VStack; inserts and deletes happen inside withAnimation(.spring) and each row carries an AnyTransition (asymmetric move, scale or a custom blur modifier transition).",
            "行由可识别的 ForEach 放在 VStack 中；增删操作在 withAnimation(.spring) 内执行，每行带有 AnyTransition（不对称位移、缩放或自定义模糊 modifier 转场）。"
        ),
        apis: ["transition", "AnyTransition.asymmetric", "AnyTransition.modifier(active:identity:)", "withAnimation", "contentTransition(.numericText())"],
        tags: ["insert", "delete", "list", "reorder", "插入", "删除", "列表", "重排"],
        params: [
            .choice("style", L("Transition", "转场样式"), [L("Slide", "滑动"), L("Pop", "弹出"), L("Blur", "模糊")]),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
        ]
    ) { ctx in
        ScrollInsertRemoveDemo(ctx: ctx)
    }
}

private struct ScrollBlurFade: ViewModifier {
    let amount: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: amount * 10)
            .opacity(1 - amount)
            .scaleEffect(1 - amount * 0.08)
    }
}

private func scrollListTransition(_ style: Int) -> AnyTransition {
    switch style {
    case 1:
        return AnyTransition.scale(scale: 0.7).combined(with: .opacity)
    case 2:
        return AnyTransition.modifier(active: ScrollBlurFade(amount: 1), identity: ScrollBlurFade(amount: 0))
    default:
        return AnyTransition.asymmetric(
            insertion: AnyTransition.move(edge: .top).combined(with: .opacity),
            removal: AnyTransition.move(edge: .trailing).combined(with: .opacity)
        )
    }
}

private struct ScrollInsertRemoveDemo: View {
    let ctx: DemoContext
    @State private var items: [Int] = [3, 2, 1, 0]
    @State private var nextID = 4
    @State private var tick = 0

    var body: some View {
        VStack(spacing: 12) {
            header
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(items, id: \.self) { id in
                        row(id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 16)
        .autoplay(ctx.isPreview, every: 1.2) { autoStep() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(L("Inbox", "收件箱"), ctx.language)
                .font(.title3.weight(.bold))
            Text(verbatim: "\(items.count)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
            Spacer(minLength: 0)
            Button(action: insert) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Palette.primary, in: Circle())
                    .shadow(color: Palette.indigo.opacity(0.35), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private func row(_ id: Int) -> some View {
        ScrollKitRow(index: id, language: ctx.language, showsMeta: false)
            .overlay(alignment: .trailing) {
                Button {
                    remove(id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
            }
            .transition(scrollListTransition(ctx.int("style")))
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    private func insert() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(spring) {
            items.insert(nextID, at: 0)
            nextID += 1
        }
    }

    private func remove(_ id: Int) {
        if !ctx.isPreview { Haptics.tap(.light) }
        withAnimation(spring) {
            items.removeAll { $0 == id }
        }
    }

    private func autoStep() {
        tick += 1
        if items.count >= 5 || (tick % 3 == 0 && items.count > 2) {
            remove(items[min(1, items.count - 1)])
        } else {
            insert()
        }
    }
}
