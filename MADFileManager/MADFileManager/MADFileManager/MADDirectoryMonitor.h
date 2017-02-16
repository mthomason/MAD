//
//  MADDirectoryMonitor.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADDirectoryMonitor_h
#define MADDesigner_MADDirectoryMonitor_h

#import <Foundation/NSObject.h>

@protocol MADDirectoryMonitorProtocol;

@interface MADDirectoryMonitor : NSObject

    @property (nonatomic, weak) id <MADDirectoryMonitorProtocol> delegate;

    - (instancetype)initWithURL:(NSURL *)URL;

    - (void)startMonitoring;
    - (void)stopMonitoring;

@end

#endif
