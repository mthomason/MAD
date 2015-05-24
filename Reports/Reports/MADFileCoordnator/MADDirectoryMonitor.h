//
//  MADDirectoryMonitor.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MADDirectoryMonitor;

/// A protocol that allows delegates of \c AAPLDirectoryMonitor to respond to changes in a directory.
@protocol MADDirectoryMonitorDelegate <NSObject>

- (void)directoryMonitorDidObserveChange:(MADDirectoryMonitor *)directoryMonitor;

@end

@interface MADDirectoryMonitor : NSObject

@property (nonatomic, weak) id<MADDirectoryMonitorDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)URL;

- (void)startMonitoring;
- (void)stopMonitoring;

@end
