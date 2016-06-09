//
//  NSError+Document.m
//  MAD
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "NSError+Document.h"
#import "MADErrorUserInfo.h"

static NSString * const MADDocumentErrorDomain = @"MADocument";

@implementation NSError (Document)

+ (instancetype)newErrorConnectionProblem {
    NSString *title = NSLocalizedString(@"Connection Problem",
                                        @"Connection Problem");
    NSString *message = NSLocalizedString(@"Could not connect to database.",
                                          @"Could not connect to database.");
    MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title
                                                                   andMessage:message];
    return [errorUserInfo errorWithDomain: MADDocumentErrorDomain code: 36732];
}

+ (instancetype)newErrorFailedToOpenDocument {
    NSString *title = NSLocalizedString(@"Failed to open document.",
                                        @"Failed to open document.");
    NSString *message = NSLocalizedString(@"Document may be incomplete, missing, or corrupt.",
                                          @"Document may be incomplete, missing, or corrupt.");
    MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title
                                                                   andMessage:message];
    return [errorUserInfo errorWithDomain: MADDocumentErrorDomain code: 260];
}

@end
