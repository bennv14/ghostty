@testable import Ghostty
import AppKit
import Testing

struct SurfaceViewAppKitTests {
    @Test(arguments: [
        ("", "x", 0, "x"),
        ("a", "â", 1, "â"),
        ("tie", "tiê", 1, "ê"),
        ("tiê", "tiế", 1, "ế"),
        ("tiếng", "tiế", 2, ""),
        ("xin", "", 3, ""),
        ("ế", "e\u{0302}\u{0301}", 0, ""),
    ])
    func calculatesStreamedPreeditDelta(
        oldValue: String,
        newValue: String,
        deleteCount: Int,
        insertText: String
    ) {
        #expect(
            Ghostty.SurfaceView.preeditDelta(
                from: oldValue,
                to: newValue
            ) == .init(
                deleteCount: deleteCount,
                insertText: insertText
            )
        )
    }

    @Test(arguments: [
        (
            "com.apple.inputmethod.VietnameseSimpleTelex",
            [String](),
            KeyboardLayout.PreeditStrategy.streamToTerminal
        ),
        (
            "third.party.input",
            ["vi"],
            KeyboardLayout.PreeditStrategy.streamToTerminal
        ),
        (
            "third.party.input",
            ["vi-VN"],
            KeyboardLayout.PreeditStrategy.streamToTerminal
        ),
        (
            "com.apple.keylayout.US",
            ["en"],
            KeyboardLayout.PreeditStrategy.native
        ),
        (
            nil,
            [String](),
            KeyboardLayout.PreeditStrategy.native
        ),
    ])
    func selectsPreeditStrategy(
        id: String?,
        languages: [String],
        expected: KeyboardLayout.PreeditStrategy
    ) {
        #expect(
            KeyboardLayout.preeditStrategy(
                id: id,
                languages: languages
            ) == expected
        )
    }

    struct ReplayCommitKeyCase: Sendable {
        let key: Ghostty.Input.Key
        let text: String?
        let committedText: String
        let modifiers: NSEvent.ModifierFlags
        let expected: Bool
    }

    private static let replayCases: [ReplayCommitKeyCase] = [
        .init(key: .space, text: " ", committedText: "tiếng", modifiers: [], expected: true),
        .init(key: .enter, text: "\r", committedText: "tiếng", modifiers: [], expected: true),
        .init(key: .arrowLeft, text: nil, committedText: "tiếng", modifiers: [], expected: true),
        .init(key: .home, text: nil, committedText: "tiếng", modifiers: [], expected: true),
        .init(key: .pageDown, text: nil, committedText: "tiếng", modifiers: [], expected: true),
        .init(key: .escape, text: "\u{1b}", committedText: "tiếng", modifiers: [], expected: true),
        .init(key: .f1, text: nil, committedText: "tiếng", modifiers: [], expected: true),
        .init(key: .numpadUp, text: nil, committedText: "tiếng", modifiers: [], expected: true),
        .init(key: .slash, text: "/", committedText: "tiếng", modifiers: [], expected: true),
        .init(key: .c, text: "c", committedText: "học", modifiers: .control, expected: true),
        .init(key: .s, text: "s", committedText: "tiếng", modifiers: [], expected: false),
        .init(key: .space, text: " ", committedText: "tiếng ", modifiers: [], expected: false),
        // Digits committed by the IME arrive via insertText and are
        // reconciled into committedText; never replay them as keys.
        .init(key: .digit1, text: "1", committedText: "tiếng", modifiers: [], expected: false),
        .init(key: .digit1, text: "1", committedText: "tiếng1", modifiers: [], expected: false),
    ]

    @Test(arguments: replayCases)
    func replaysOnlyStreamedPreeditCommitDelimiter(
        testCase: ReplayCommitKeyCase
    ) {
        #expect(
            Ghostty.SurfaceView.shouldReplayStreamedPreeditCommitKey(
                testCase.key,
                text: testCase.text,
                committedText: testCase.committedText,
                modifiers: testCase.modifiers
            ) == testCase.expected
        )
    }

    @Test(arguments: [
        ("\u{0008}", true),
        ("\u{001F}", true),
        ("\u{007F}", false),
        (" ", false),
        ("h", false),
        ("", false),
        ("\u{0009}x", false),
        ("\u{0009}\u{0009}", false),
    ])
    func suppressesOnlySingleC0ControlTextWhileComposing(
        text: String,
        expected: Bool
    ) {
        #expect(
            Ghostty.SurfaceView.shouldSuppressComposingControlInput(
                text,
                composing: true
            ) == expected
        )
    }

    @Test func doesNotSuppressControlTextWhenNotComposing() {
        #expect(
            Ghostty.SurfaceView.shouldSuppressComposingControlInput(
                "\u{0008}",
                composing: false
            ) == false
        )
    }

    @Test func doesNotSuppressMissingText() {
        #expect(
            Ghostty.SurfaceView.shouldSuppressComposingControlInput(
                nil,
                composing: true
            ) == false
        )
    }
}
