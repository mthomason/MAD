//
//  MADInterfaceControllerKPI.m
//  MAD
//
//  Created by Michael Thomason on 4/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADInterfaceControllerKPI.h"
#import "MAD.h"

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
    [self setTitle:title];
    
    NSLog(@"%@", context);
    
    MADocument *document = [[MADocument alloc] initWithFileURL:self.madFile];
    self.document = document;
    [self.document openWithCompletionHandler:^(BOOL success) {
        
        [self.document activeDocumentModel];
        NSLog(@"%@", success ? @"YES" : @"NO");
        
    }];
    //AAPLListInfo *listInfo = context;
    //self.listDocument = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL];
    
    //[self setTitle:listInfo.name];
    //[self setUpInterfaceTable];
    
    // Configure interface objects here.
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    [self.document closeWithCompletionHandler:nil];
}

@end



