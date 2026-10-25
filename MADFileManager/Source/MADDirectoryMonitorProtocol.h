//
//  MADDirectoryMonitorProtocol.h
//  MADFileManager
//
//  Created by Michael on 2/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDirectoryMonitorProtocol_h
#define MADDirectoryMonitorProtocol_h

@class MADDirectoryMonitor;

@protocol MADDirectoryMonitorProtocol <NSObject>
	- (void)directoryMonitorDidObserveChange:(MADDirectoryMonitor *)directoryMonitor;
@end

#endif /* MADDirectoryMonitorProtocol_h */
