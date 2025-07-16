#ifndef CEF_MANAGER_H_
#define CEF_MANAGER_H_

#ifdef __cplusplus
extern "C" {
#endif

void CefManager_Initialize();
void CefManager_DoMessageLoopWork();
void CefManager_Shutdown();

#ifdef __cplusplus
}
#endif

#endif // CEF_MANAGER_H_