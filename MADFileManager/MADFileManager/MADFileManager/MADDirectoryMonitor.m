//
//  MADDirectoryMonitor.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDirectoryMonitor.h"

@interface MADDirectoryMonitor ()

@property (nonatomic, assign) int monitoredDirectoryFileDescriptor;
@property (nonatomic, strong) dispatch_queue_t directoryMonitorQueue;
@property (nonatomic, strong) dispatch_source_t directoryMonitorSource;
@property (nonatomic, strong) NSURL *URL;

@end

@implementation MADDirectoryMonitor
#pragma mark - Initializers

- (instancetype)initWithURL:(NSURL *)URL {

    if (self = [super init]) {
        self.URL = URL;
        self.monitoredDirectoryFileDescriptor = 0;
    }
    
    return self;
}

#pragma mark - Monitoring

- (void)startMonitoring {

    if (self.directoryMonitorSource == nil && self.monitoredDirectoryFileDescriptor == -1) {
        self.monitoredDirectoryFileDescriptor = open([self.URL.path cStringUsingEncoding:NSUTF8StringEncoding], O_EVTONLY);
        if (self.monitoredDirectoryFileDescriptor >= 0) {
            self.directoryMonitorQueue = dispatch_queue_create("com.everydayapps.mad.filesystem.watcher", DISPATCH_QUEUE_CONCURRENT);
            
            unsigned long mask = DISPATCH_VNODE_DELETE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_ATTRIB;
            self.directoryMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, (uintptr_t)self.monitoredDirectoryFileDescriptor, mask, self.directoryMonitorQueue);
            
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
}

- (void)stopMonitoring {
    if (self.directoryMonitorSource != nil) {
        dispatch_source_cancel(self.directoryMonitorSource);
    }
}

@end
