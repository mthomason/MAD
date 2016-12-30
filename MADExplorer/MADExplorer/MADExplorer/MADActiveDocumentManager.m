//
//  MADFileManager
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADActiveDocumentManager.h"
#import <UIKit/UIManagedDocument.h>

NSString * const MADFileManagerOpenUrl      = @"MADFileManagerOpenUrl";
NSString * const MADFileManagerOpenFiles    = @"MADFileManagerOpenFiles";

typedef NSMutableDictionary <NSString *, __kindof UIManagedDocument *> MADDocumentHolder;

@interface MADActiveDocumentManager ()

    @property (nonatomic, strong) MADDocumentHolder *openFiles;   //MADocument stored by their NSURLS
    @property (nonatomic, copy, readwrite) NSURL *openUrl;

@end

@implementation MADActiveDocumentManager

- (void)dealloc {
    [_openFiles removeAllObjects];
    _openFiles = nil;
}

- (instancetype)init {
    if (self = [super init]) {
        MADDocumentHolder *openFiles = [[MADDocumentHolder alloc] init];
        self.openFiles = openFiles;
        self.openUrl = nil;
    }
    return self;
}

- (void)setOpenDocument:(__kindof UIManagedDocument *)document {
    if (document) {
        self.openUrl = document.fileURL.copy;
        NSString *path = self.openUrl.absoluteURL.absoluteString;
        self.openFiles[path] = document;
    }
}

- (__kindof UIManagedDocument *)openDocument {
    NSURL *absoluteURL = self.openUrl.absoluteURL;
    NSString *absoluteString = absoluteURL.absoluteString;
    return absoluteString != nil ? self.openFiles[absoluteString] : nil;
}

- (void)unload {
    NSURL *openURL = self.openUrl.copy;
    [self removeDocumentWithUrl: openURL];
}

- (void)removeDocumentWithUrl:(NSURL *)url {
    NSURL *absoluteURL = self.openUrl.absoluteURL;
    NSString *absoluteString = absoluteURL.absoluteString;
    [self.openFiles removeObjectForKey:absoluteString];
    
    if ([url isEqual:self.openUrl]) {
        self.openUrl = nil;
    }
}

@end
