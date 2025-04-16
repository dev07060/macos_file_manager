import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
      let flutterViewController = FlutterViewController()
      let windowFrame = self.frame
      self.contentViewController = flutterViewController
      self.setFrame(windowFrame, display: true)
      
      // 윈도우 최소 사이즈 설정
      self.minSize = NSSize(width: 800, height: 600) // 원하는 최소 크기로 조정
      
      RegisterGeneratedPlugins(registry: flutterViewController)

      super.awakeFromNib()
    }
}
