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
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqRect.h"
#import "RptqPoint.h"
#import "RptqSize.h"
#import "RptqDirectionalAsymmetry.h"
#import "RptqBorder.h"

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

		// The element auto-height the Core Data projection computed: the maximum,
		// over the section's elements, of
		//   rect.origin.y + rect.size.height
		//   + margin.top + margin.bottom
		//   + padding.top + padding.bottom
		//   + border.width.top + border.width.bottom
		// where a missing edge contributes 0, the way the projection's NULLs did.
		// This is what MADReportFormatter advances cumulativePageHeight by, so it
		// must come from the elements, not from the section's declared height.
		if (_visibility) {
			RptqDocumentSection *section = (RptqDocumentSection *)[managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentSection class])
																	  identifier:_identifier];
			for (RptqDocumentSectionRows *row in section.hasRows) {
				for (RptqDocumentElement *element in row.hasObjects) {
					double calculatedHeight = 0.0;
					RptqRect *rect = element.rect;
					if (rect != nil) calculatedHeight += rect.origin.y + rect.size.height;
					RptqDirectionalAsymmetry *margin = element.margin;
					if (margin != nil) calculatedHeight += margin.top + margin.bottom;
					RptqDirectionalAsymmetry *padding = element.padding;
					if (padding != nil) calculatedHeight += padding.top + padding.bottom;
					RptqBorder *border = element.border;
					if (border != nil) calculatedHeight += border.width.top + border.width.bottom;
					_displayHeight = MAX(_displayHeight, (float)calculatedHeight);
				}
			}
		} else {
			_displayHeight = 0.0000f;
		}
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
