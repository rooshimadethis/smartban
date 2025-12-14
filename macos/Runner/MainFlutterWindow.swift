import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    var windowFrame = self.frame
    // Increase size: 30% wider, 20% taller
    let newWidth = windowFrame.size.width * 1.3
    let newHeight = windowFrame.size.height * 1.2
    // Re-center roughly (optional, but good practice if we grow significantly) or just let macOS handle it.
    // We'll just update the size keeping the origin or letting setFrame handle it.
    // Actually setFrame takes a rect.
    let newFrame = NSRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: newWidth, height: newHeight)
    
    self.contentViewController = flutterViewController
    self.setFrame(newFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
