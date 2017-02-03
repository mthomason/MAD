//
//  RptqDocumentElementLabelLink+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElementLabelLink+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"

#import "RptqDataHelper.h"

@implementation RptqDocumentElementLabelLink (Extras)

#pragma mark -
#pragma mark Overrides

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %lld\n", self.identifier];
    [description appendFormat:@"Text:                   %@\n", self.text];
    [description appendFormat:@"URL:                    %@\n", self.url];
    [description appendFormat:@"*********"];
    return description;
}

- (NSString *)designerRepresentationText {
    return @"";
}

@end
