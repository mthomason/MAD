//
//  MADDirectoryMonitor.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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
