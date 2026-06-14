import AppKit

enum ScreenUtility {
    static func activeScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
            ?? NSScreen()
    }
}
