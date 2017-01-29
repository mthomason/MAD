//
//  MADInterfaceControllerKPI.m
//  MAD
//
//  Created by Michael Thomason on 4/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADInterfaceControllerKPI.h"

@interface MADInterfaceControllerKPI()

@property (nonatomic, strong) NSURL *madFile;
@property (nonatomic, weak) MADocument *document;

@end


@implementation MADInterfaceControllerKPI

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    NSURL *fileURL = context;
    self.madFile = fileURL;
    
    NSString *title = [self.madFile.lastPathComponent stringByDeletingPathExtension];
    self.title = title;
    
    MADocument *document = [[MADocument alloc] initWithFileURL:self.madFile];
    self.document = document;
    [self.document openWithCompletionHandler:^(BOOL success) {
        [self.document activeDocumentModel];
    }];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    [MADocument close: self.document completion:^(BOOL success) {}];
}

@end



