//
//  RptqDocumentElementGroupKey+Extras.m
//  MAD
//
//  Created by Michael on 1/30/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqStoreContext.h"
#import "RptqDocumentElementGroupKey+Extras.h"

#import <Foundation/NSNumberFormatter.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>

@implementation RptqDocumentElementGroupKey (Extras)

- (NSString *)designerRepresentationText {
	NSString *groupNumberText = [NSNumberFormatter localizedStringFromNumber: [NSNumber numberWithLongLong:self.groupNumber]
																 numberStyle: NSNumberFormatterSpellOutStyle];
	return [[NSString alloc] initWithFormat:NSLocalizedString(@"Group %@", @"Like 'Group Three.'"), groupNumberText.uppercaseString];
}

@end
