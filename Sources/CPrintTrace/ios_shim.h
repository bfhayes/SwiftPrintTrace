#ifndef CPRINTTRACE_IOS_SHIM_H
#define CPRINTTRACE_IOS_SHIM_H

// iOS-specific shim for PrintTrace when using XCFramework
#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH

// Import from the iOS framework
#import <PrintTrace/PrintTraceAPI.h>

#else

// Import the regular C API for macOS/Linux
#include <PrintTraceAPI.h>

#endif

#endif /* CPRINTTRACE_IOS_SHIM_H */