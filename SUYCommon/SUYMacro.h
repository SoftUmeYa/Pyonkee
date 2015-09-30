//
//  SUYMacro.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/04/10.

#import "LoggerClient.h"

// NSLogger
#ifdef SUY_DEBUG
#define NSLog(...)                      LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"NSLog", 0, __VA_ARGS__)
#define LoggerError(level, ...)         LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Error", level, __VA_ARGS__)
#define LoggerApp(level, ...)           LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"App", level, __VA_ARGS__)
#define LoggerView(level, ...)          LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"View", level, __VA_ARGS__)
#define LoggerService(level, ...)       LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Service", level, __VA_ARGS__)
#define LoggerModel(level, ...)         LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Model", level, __VA_ARGS__)
#define LoggerData(level, ...)          LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Data", level, __VA_ARGS__)
#define LoggerNetwork(level, ...)       LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Network", level, __VA_ARGS__)
#define LoggerLocation(level, ...)      LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Location", level, __VA_ARGS__)
#define LoggerPush(level, ...)          LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Push", level, __VA_ARGS__)
#define LoggerFile(level, ...)          LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"File", level, __VA_ARGS__)
#define LoggerSharing(level, ...)       LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Sharing", level, __VA_ARGS__)
#define LoggerAd(level, ...)            LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Ad and Stat", level, __VA_ARGS__)

#else
#define NSLog(...)                      while(0) {} //LogMessageCompat(__VA_ARGS__)
#define LoggerError(...)                while(0) {}
#define LoggerApp(level, ...)           while(0) {}
#define LoggerView(...)                 while(0) {}
#define LoggerService(...)              while(0) {}
#define LoggerModel(...)                while(0) {}
#define LoggerData(...)                 while(0) {}
#define LoggerNetwork(...)              while(0) {}
#define LoggerLocation(...)             while(0) {}
#define LoggerPush(...)                 while(0) {}
#define LoggerFile(...)                 while(0) {}
#define LoggerSharing(...)              while(0) {}
#define LoggerAd(...)                   while(0) {}

#endif

#define nslogger_xstr(s) nslogger_str(s)
#define nslogger_str(s) #s
#define LoggerStartForBuildUser() LoggerSetupBonjour(LoggerGetDefaultLogger(), NULL, CFSTR(xstr(NSLOGGER_BUILD_USERNAME)))
// NSLogger

#define LOG_LV_FATAL	0
#define	LOG_LV_ERROR	1
#define	LOG_LV_WARN     2
#define	LOG_LV_INFO		3
#define	LOG_LV_TRACE	4

#define LgFatal(...)           LoggerError(LOG_LV_FATAL, __VA_ARGS__)
#define LgError(...)           LoggerError(LOG_LV_ERROR, __VA_ARGS__)
#define LgWarn(...)           LoggerError(LOG_LV_WARN, __VA_ARGS__)
#define LgInfo(...)           LoggerApp(LOG_LV_INFO, __VA_ARGS__)
#define LgTrace(...)           LoggerApp(LOG_LV_TRACE, __VA_ARGS__)

// iOS Version
#define OVER_IOS8 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8)
#define OVER_IOS9 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9)

