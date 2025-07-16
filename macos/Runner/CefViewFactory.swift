import FlutterMacOS
import Cocoa

/// FlutterPlatformView를 구현하여 네이티브 NSView를 관리하는 클래스
class CefPlatformView: NSObject, FlutterPlatformView {
    private let webView: NSView
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        // 실제 웹뷰를 담을 NSView를 생성합니다.
        webView = NSView(frame: frame)
        super.init()

        // 웹뷰 영역을 시각적으로 확인하기 위한 배경색 (개발 중)
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.lightGray.cgColor
        
        if let arguments = args as? [String: Any],
           let url = arguments["initialUrl"] as? String {
            // C 문자열로 변환
            url.withCString { cString in
                // NSView의 포인터를 C 함수로 전달하여 웹뷰 생성
                let viewPointer = Unmanaged.passUnretained(webView).toOpaque()
                create_webview(viewPointer, cString, CInt(frame.width), CInt(frame.height))
            }
        }
    }

    // FlutterPlatformView 프로토콜 요구사항.
    // Flutter에 표시할 실제 NSView를 반환합니다.
    func view() -> NSView {
        return webView
    }
}

// 네이티브 NSView를 생성하는 팩토리 클래스
class CefViewFactory: NSObject, FlutterPlatformViewFactory {
    private weak var messenger: FlutterBinaryMessenger?

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    // FlutterPlatformViewFactory 프로토콜 요구사항.
    // FlutterPlatformView를 구현하는 객체를 생성하여 반환합니다.
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return CefPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }

    // create 메서드에 전달되는 arguments를 디코딩하기 위한 코덱을 지정합니다.
    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return nil
    }
}
