import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var timer: Timer?

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // 상태 복원 기능을 지원하도록 함수 추가
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // 앱이 실행 완료된 후 팩토리를 등록합니다.
    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 1. CEF 런타임을 초기화합니다.
        CefManager_Initialize()
        
        guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
            fatalError("Could not get FlutterViewController")
        }
        
        // PlatformView 팩토리를 등록합니다.
        let viewFactory = CefViewFactory(messenger: controller.engine.binaryMessenger)
        controller.engine.registrar(forPlugin: "CefViewFactory")
            .register(viewFactory, withId: "com.example/cef_webview")
        
        // 2. CEF 메시지 루프를 주기적으로 실행하기 위한 타이머를 설정합니다.
        //    약 30fps로 실행하여 UI 반응성을 유지합니다.
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            CefManager_DoMessageLoopWork()
        }
    }

    override func applicationWillTerminate(_ aNotification: Notification) {
        // 3. 애플리케이션이 종료되기 전에 CEF 리소스를 정리합니다.
        self.timer?.invalidate()
        self.timer = nil
        CefManager_Shutdown()
    }
}
