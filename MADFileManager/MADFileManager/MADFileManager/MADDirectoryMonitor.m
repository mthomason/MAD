//
//  MADDirectoryMonitor.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDirectoryMonitor.h"
#import <Foundation/NSURL.h>
#include <dispatch/dispatch.h>
#import <sys/unistd.h>
#import <sys/fcntl.h>

@interface MADDirectoryMonitor ()

    @property (nonatomic, assign) int fileDescriptor;
    @property (nonatomic, strong) dispatch_queue_t directoryMonitorQueue;
    @property (nonatomic, strong) dispatch_source_t directoryMonitorSource;
    @property (nonatomic, strong) NSURL *URL;

@end

const char * MADQueueFileSystemWatcher = "com.everydayapps.mad.filesystem.watcher";

@implementation MADDirectoryMonitor
#pragma mark - Initializers

- (instancetype)initWithURL:(NSURL *)URL {

    if (self = [super init]) {
        self.URL = URL;
        self.fileDescriptor = 0;
    }
    
    return self;
}

#pragma mark - Monitoring

- (void)startMonitoring {

    if (self.directoryMonitorSource == nil && self.fileDescriptor == -1) {
        const char *path = [self.URL.path cStringUsingEncoding:NSUTF8StringEncoding];
        self.fileDescriptor = open(path, O_EVTONLY);
        if (self.fileDescriptor >= 0) {
            
            id directoryMonitorQueue = dispatch_queue_create(MADQueueFileSystemWatcher,
                                                            DISPATCH_QUEUE_CONCURRENT);
            self.directoryMonitorQueue = directoryMonitorQueue;
            
            unsigned long mask = DISPATCH_VNODE_DELETE | DISPATCH_VNODE_EXTEND |
                                 DISPATCH_VNODE_RENAME | DISPATCH_VNODE_ATTRIB;
            
            id directoryMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                               (uintptr_t)self.fileDescriptor,
                                                               mask, self.directoryMonitorQueue);
            self.directoryMonitorSource = directoryMonitorSource;
            
            dispatch_source_set_event_handler(self.directoryMonitorSource, ^{
                [self.delegate directoryMonitorDidObserveChange:self];
            });
            
            dispatch_source_set_cancel_handler(self.directoryMonitorSource, ^{
                close(self.fileDescriptor);
                self.fileDescriptor = -1;
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
