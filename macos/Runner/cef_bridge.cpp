#include "cef_bridge.h"
#include "../CEF/include/cef_app.h"
#include "../CEF/include/cef_client.h"
#include "../CEF/include/cef_browser.h"
#include "../CEF/include/wrapper/cef_helpers.h"
#include <list>

// 간단한 CEF 클라이언트 구현 (라이프사이클 관리 등)
class SimpleClient : public CefClient, public CefLifeSpanHandler {
public:
    SimpleClient() {}

    // CefLifeSpanHandler methods:
    void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
        CEF_REQUIRE_UI_THREAD();
        // We now have a browser instance.
        if (!browser_list_.empty()) {
            // We could support multiple browser instances, but for now we'll just track the last one created.
        }
        browser_list_.push_back(browser);
    }

    void OnBeforeClose(CefRefPtr<CefBrowser> browser) override {
        CEF_REQUIRE_UI_THREAD();
        // Remove the browser from our list of tracked instances.
        browser_list_.remove(browser);
    }

    virtual CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override { return this; }
    // ... 기타 필요한 핸들러 오버라이드 ...
private:
    // List of existing browser windows.
    std::list<CefRefPtr<CefBrowser>> browser_list_;

    IMPLEMENT_REFCOUNTING(SimpleClient);
};

void create_webview(void* view, const char* url, int width, int height) {
    CEF_REQUIRE_UI_THREAD();

    CefWindowInfo window_info;
    CefBrowserSettings browser_settings;

    // 네이티브 NSView에 웹뷰를 자식으로 추가
    window_info.SetAsChild(reinterpret_cast<CefWindowHandle>(view), {0, 0, width, height});

    CefRefPtr<SimpleClient> handler(new SimpleClient());

    // 브라우저 생성
    CefBrowserHost::CreateBrowser(window_info, handler, url, browser_settings, nullptr, nullptr);
}
