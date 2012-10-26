//
//  UIManagedDocumentTrvFileData.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIManagedDocumentQuery.h"
#import <CoreData/CoreData.h>
#import "Constants.h"

@implementation UIManagedDocumentQuery

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    NSLog(@"Auto-Saving Document");
    return [super contentsForType:typeName error:outError];
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {   
    NSLog(@"UIManagedDocument error: %@", error.localizedDescription);
    NSArray* errors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if(errors != nil && errors.count > 0) {
        for (NSError *error in errors) {
            NSLog(@"  Error: %@", error.userInfo);
        }
    } else {
        NSLog(@"  %@", error.userInfo);
    }
}

+ (NSString *)persistentStoreName {
    return QUERYDATA_FILENAME;
}

@end