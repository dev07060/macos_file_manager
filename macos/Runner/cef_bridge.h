//
//  cef_bridge.h
//  Runner
//
//  Created by dev_bh on 7/16/25.
//


#ifndef cef_bridge_h
#define cef_bridge_h

#ifdef __cplusplus
extern "C" {
#endif

// 웹뷰를 생성하고 지정된 URL을 로드하는 함수
// view: 웹뷰를 추가할 네이티브 NSView의 포인터
// url: 로드할 웹사이트 주소
// width, height: 웹뷰의 크기
void create_webview(void* view, const char* url, int width, int height);

#ifdef __cplusplus
}
#endif

#endif /* cef_bridge_h */