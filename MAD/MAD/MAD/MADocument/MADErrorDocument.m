//
//  NSError+Document.m
//  MAD
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADErrorDocument.h"
#import <Foundation/NSBundle.h>
#import <MADFoundation/MADErrorUserInfo.h>

static NSString * const MADDocumentErrorDomain = @"MADocument";

@implementation MADErrorDocument

+ (instancetype)newErrorConnectionProblem {
    NSString *title = NSLocalizedString(@"Connection Problem",
                                        @"Connection Problem");
    NSString *message = NSLocalizedString(@"Could not connect to database.",
                                          @"Could not connect to database.");
    MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title
                                                                   andMessage:message];
    id error = [errorUserInfo errorWithDomain: MADDocumentErrorDomain code: 36732];
    return error;
}

+ (instancetype)newErrorFailedToOpenDocument {
    NSString *title = NSLocalizedString(@"Failed to open document.",
                                        @"Failed to open document.");
    NSString *message = NSLocalizedString(@"Document may be incomplete, missing, or corrupt.",
                                          @"Document may be incomplete, missing, or corrupt.");
    MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title
                                                                   andMessage:message];
    id error = [errorUserInfo errorWithDomain: MADDocumentErrorDomain code: 260];
    return error;
}

@end
