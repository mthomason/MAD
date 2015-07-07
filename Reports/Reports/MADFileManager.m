//
//  MADFileManager
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADFileManager.h"

NSString * const MADFileManagerOpenUrl      = @"MADFileManagerOpenUrl";
NSString * const MADFileManagerOpenFiles    = @"MADFileManagerOpenFiles";

@interface MADFileManager ()

@property (nonatomic, strong) NSMutableDictionary *openFiles;   //MADocument stored by their NSURLS
@property (nonatomic, strong, readwrite) NSURL *openUrl;


@end

@implementation MADFileManager

@dynamic openDocument;

- (void)dealloc {
    [self.openFiles removeAllObjects];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSMutableDictionary *openFiles = [[NSMutableDictionary alloc] init];
        self.openFiles = openFiles;
        self.openUrl = nil;
    }
    return self;
}

- (void)setOpenDocument:(UIManagedDocument *)document {
    if (document) {
        self.openUrl = document.fileURL;
        self.openFiles[self.openUrl.absoluteString] = document;
    }
}

- (UIManagedDocument *)openDocument {
    return self.openFiles[self.openUrl.absoluteString];
}

- (void)removeDocumentWithUrl:(NSURL *)url {
    [self.openFiles removeObjectForKey:url.absoluteString];
}

@end
