//
//  madlog.h
//  MAD Designer
//
//  Created by Michael on 5/16/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_madlog_h
#define MADDesigner_madlog_h

#import <os/log.h>

os_log_t GetDesignerLog(void);

#if DEBUG
	#define MADLogDebug(fmt, ...) os_log_debug(GetDesignerLog(), fmt, ##__VA_ARGS__)
#else
	#define MADLogDebug(fmt, ...) do {} while (0)
#endif

#define MADLogInfo(fmt, ...)  os_log_info(GetDesignerLog(), fmt, ##__VA_ARGS__)
#define MADLogError(fmt, ...) os_log_error(GetDesignerLog(), fmt, ##__VA_ARGS__)
#define MADLogFault(fmt, ...) os_log_fault(GetDesignerLog(), fmt, ##__VA_ARGS__)

#endif /* madlog_h */
