//
//  MADDirectoryMonitor.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDirectoryMonitor.h"

@interface MADDirectoryMonitor ()

@property (nonatomic) int monitoredDirectoryFileDescriptor;
@property (nonatomic, strong) dispatch_queue_t directoryMonitorQueue;
@property (nonatomic, strong) dispatch_source_t directoryMonitorSource;
@property (nonatomic, strong) NSURL *URL;

@end

@implementation MADDirectoryMonitor
#pragma mark - Initializers

- (instancetype)initWithURL:(NSURL *)URL {

    if (self = [super init]) {
        self.URL = URL;
        self.monitoredDirectoryFileDescriptor = -1;
    }
    
    return self;
}

#pragma mark - Monitoring

- (void)startMonitoring {

    if (self.directoryMonitorSource == nil && self.monitoredDirectoryFileDescriptor == -1) {
        self.monitoredDirectoryFileDescriptor = open([self.URL.path cStringUsingEncoding:NSUTF8StringEncoding], O_EVTONLY);
        
        self.directoryMonitorQueue = dispatch_queue_create("com.everydayapps.mad.filesystem.watcher", DISPATCH_QUEUE_CONCURRENT);
        
        self.directoryMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, self.monitoredDirectoryFileDescriptor, DISPATCH_VNODE_WRITE, self.directoryMonitorQueue);
        
        dispatch_source_set_event_handler(self.directoryMonitorSource, ^{
            [self.delegate directoryMonitorDidObserveChange:self];
        });
        
        dispatch_source_set_cancel_handler(self.directoryMonitorSource, ^{
            close(self.monitoredDirectoryFileDescriptor);
            self.monitoredDirectoryFileDescriptor = -1;
            self.directoryMonitorSource = nil;
        });
        dispatch_resume(self.directoryMonitorSource);
    }
}

- (void)stopMonitoring {
    if (self.directoryMonitorSource != nil) {
        dispatch_source_cancel(self.directoryMonitorSource);
    }
}

@end
