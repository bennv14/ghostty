import AppKit
import Carbon

class KeyboardLayout {
    enum PreeditStrategy: Equatable {
        case native
        case streamToTerminal
    }

    private static var currentInputSource: TISInputSource? {
        TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }

    /// Return a string ID of the current keyboard input source.
    static var id: String? {
        if let source = currentInputSource,
           let sourceIdPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) {
            let sourceId = unsafeBitCast(sourceIdPointer, to: CFString.self)
            return sourceId as String
        }

        return nil
    }

    /// Translate a physical keycode for use as a menu key equivalent.
    ///
    /// AppKit retranslates against the current input source without changing its dead key state.
    ///
    /// - Important: Must be called on the main thread because underlying Text Input Sources APIs are not thread-safe.
    @MainActor static func character(
        for keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags
    ) -> Character? {
        guard
            let event = NSEvent.keyEvent(
                with: .keyDown,
                location: .zero,
                modifierFlags: [],
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                characters: "",
                charactersIgnoringModifiers: "",
                isARepeat: false,
                keyCode: keyCode),
            let result = event.characters(byApplyingModifiers: modifiers),
            result.count == 1
        else { return nil }

        return result.first
    }

    static var preeditStrategy: PreeditStrategy {
        guard let source = currentInputSource else { return .native }

        let sourceId: String? = if let pointer = TISGetInputSourceProperty(
            source,
            kTISPropertyInputSourceID
        ) {
            unsafeBitCast(pointer, to: CFString.self) as String
        } else {
            nil
        }

        let languages: [String] = if let pointer = TISGetInputSourceProperty(
            source,
            kTISPropertyInputSourceLanguages
        ) {
            unsafeBitCast(pointer, to: CFArray.self) as? [String] ?? []
        } else {
            []
        }

        return preeditStrategy(id: sourceId, languages: languages)
    }

    static func preeditStrategy(
        id: String?,
        languages: [String]
    ) -> PreeditStrategy {
        if id?.localizedCaseInsensitiveContains("vietnamese") == true {
            return .streamToTerminal
        }

        let isVietnamese = languages.contains { language in
            let language = language.lowercased()
            return language == "vi" ||
                language.hasPrefix("vi-") ||
                language.hasPrefix("vi_")
        }

        return isVietnamese ? .streamToTerminal : .native
    }
}
