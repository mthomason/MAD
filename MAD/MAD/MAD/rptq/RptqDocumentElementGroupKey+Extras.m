//
//  RptqDocumentElementGroupKey+Extras.m
//  MAD
//
//  Created by Michael on 1/30/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDocumentElementGroupKey+Extras.h"

#import <Foundation/NSNumberFormatter.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>

@implementation RptqDocumentElementGroupKey (Extras)

- (NSString *)designerRepresentationText {
    NSString *result = nil;
    NSNumber *groupNumber = [NSNumber numberWithLongLong:self.groupNumber];
    NSString *groupNumberText = [NSNumberFormatter localizedStringFromNumber: groupNumber
                                                                 numberStyle: NSNumberFormatterSpellOutStyle];
    NSString *gorupFormatString = NSLocalizedString(@"Group %@", @"Like 'Group Three.'");
    result = [[NSString alloc] initWithFormat:gorupFormatString, groupNumberText.uppercaseString];
    return result;
}

@end
