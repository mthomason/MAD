//
//  MADDirectoryMonitorProtocol.h
//  MADFileManager
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDirectoryMonitorProtocol_h
#define MADDirectoryMonitorProtocol_h

@class MADDirectoryMonitor;

@protocol MADDirectoryMonitorProtocol <NSObject>
    - (void)directoryMonitorDidObserveChange:(MADDirectoryMonitor *)directoryMonitor;
@end

#endif /* MADDirectoryMonitorProtocol_h */
