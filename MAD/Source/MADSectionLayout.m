//
//  MADSectionLayout.m
//  MAD
//
//  Created by Michael on 5/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADSectionLayout.h"
#import <MAD/RptqStoreContext.h>
#import <CoreFoundation/CFNumber.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>
#import "MADocumentSectionType.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"

@implementation MADSectionLayout {
  @public
	int64_t _identifier;
	MADDocumentSectionType _type;
	float _height;
	NSUInteger _groupLevel;
	NSUInteger _numberOfRows;
	BOOL _visibility;
	RptqDocumentSectionWrappingStyle _wrappingStyle;
}

- (instancetype)initWithObject:(NSDictionary *)object
		  managedObjectContext:(RptqStoreContext *)managedObjectContext {
	if (self = [super init]) {
		
		NSString *keyIdentifier = NSStringFromSelector(@selector(identifier)),
				 *keyPathNumberOfRows = [RptqDocumentSection keyPathNumberOfRows],
				 *keyPathType = [RptqDocumentSection keyPathType],
				 *keyPathWrappingStyle = [RptqDocumentSection keyPathWrappingStyle],
				 *keyPathVisibility = [RptqDocumentSection keyPathVisibility],
				 *keyPathHeight = [RptqDocumentSection keyPathHeight];
		
		NSNumber *number = object[keyIdentifier];
		_identifierObject = number.copy;
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt64Type, &_identifier);
		
		number = object[keyPathHeight];
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberDoubleType, &_height);
		
		number = object[keyPathNumberOfRows];
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt64Type, &_numberOfRows);
		
		number = object[keyPathType];
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt64Type, &_type);
		
		number = object[keyPathVisibility];
		_visibility = number.boolValue;
		
		number = object[keyPathWrappingStyle];
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_wrappingStyle);

		// Element auto-height was a Core Data projection over each element's margin,
		// padding, border and rect; the store drops projections, so the section's own
		// declared height stands in until the sections/elements family lands (slice 3).
		_displayHeight = _visibility ? _height : 0.0000f;
	}
	return self;
}

- (BOOL)producesFormFeed {
	return (self.wrappingStyle) == RptqDocumentSectionWrappingStyleNewPageAfter;
}

- (NSString *)localizedDisplay {
	NSString *result = nil;
	switch (self.type) {
			
		case MADDocumentSectionTypeReportHeader:
			result = NSLocalizedString(@"Report Header", @"Report Header");
			break;
			
		case MADDocumentSectionTypePageHeader:
			result = NSLocalizedString(@"Page Header", @"Page Header");
			break;
			
		case MADDocumentSectionTypeBody:
			result = NSLocalizedString(@"Report Detail", @" Report Detail");
			break;
			
		case MADDocumentSectionTypePageFooter:
			result = NSLocalizedString(@"Page Footer", @"Page Footer");
			break;
			
		case MADDocumentSectionTypeReportFooter:
			result = NSLocalizedString(@"Report Footer", @"Report Footer");
			break;
			
		case MADDocumentSectionTypeGroupHeader:
			NSAssert(true, @"Probably fucking up somehow.  Use a subclass for the group.");
			result = NSLocalizedString(@"Group Header", @"\"Group Header\"");
			break;
			
		case MADDocumentSectionTypeGroupFooter:
			NSAssert(true, @"Probably fucking up somehow.  Use a subclass for the group.");
			result = NSLocalizedString(@"Group Footer", @"\"Group Footer\"");
			break;
			
		default:
			break;
			
	}
	return result;
}

@end
