#include "cef_manager.h"
#include "../CEF/include/cef_app.h"

// CefApp의 기본 구현입니다.
// 애플리케이션 수준의 콜백을 처리하기 위해 필요합니다.
class SimpleApp : public CefApp {
public:
    SimpleApp() {}

private:
    IMPLEMENT_REFCOUNTING(SimpleApp);
    DISALLOW_COPY_AND_ASSIGN(SimpleApp);
};

void CefManager_Initialize() {
    // macOS에서는 CefMainArgs가 필요하지 않을 수 있지만, 형식상 전달합니다.
    CefMainArgs main_args;

    CefSettings settings;

    // 디버깅을 위해 샌드박스를 비활성화합니다.
    // 프로덕션 환경에서는 샌드박스 설정을 신중하게 다루어야 합니다.
    settings.no_sandbox = 1;

    // CefApp 인스턴스를 생성하여 전달합니다.
    CefRefPtr<SimpleApp> app(new SimpleApp());

    // CEF를 초기화합니다.
    bool result = CefInitialize(main_args, settings, app.get(), nullptr);
    if (!result) {
        // 초기화 실패 처리
    }
}

void CefManager_DoMessageLoopWork() {
    CefDoMessageLoopWork();
}

void CefManager_Shutdown() {
    CefShutdown();
}