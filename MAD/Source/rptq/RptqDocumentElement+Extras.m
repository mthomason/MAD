//
//  RptqDocumentElement+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElement+Extras.h"

#import "MADAlignment.h"
#import "MADFont.h"

#import "RptqDirectionalAsymmetry.h"
#import "RptqNumericFormat.h"
#import "RptqAlignment.h"
#import "RptqRect+Extras.h"
#import "RptqSize+Extras.h"
#import "RptqPoint+Extras.h"
#import "RptqTextStyle.h"
#import "RptqBorder+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDocumentElementGroupKey.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqDocumentElementAggregate+Extras.h"
#import "RptqDocumentElementFormula.h"
#import "RptqDocumentElementGroupKey.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElementImage.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementBarcode.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDirectionalAsymmetry+Extras.h"
#import "RptqDirectionalProperty+Extras.h"

#import "MADSectionLayoutManager.h"
#import "RptqDocumentElementBarcode+Extras.h"

#import "MADCurrencyFormatter.h"

#import <MADFoundation/MADStringUtilities.h>

#import <UIKit/UIFontDescriptor.h>
#import <UIKit/UIGeometry.h>

#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>

#import <Foundation/NSNumberFormatter.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSData.h>

#import <asl.h>
#import <math.h>
#import <os/log.h>

static os_log_t rptq_log;

NSString * const MTDocumentObjectDefinationType = @"MTDocumentObjectDefinationType";
NSString * const MTDocumentObjectDefinationObject = @"MTDocumentObjectDefinationObject";

NSString * const MTDocumentObjectDefinationAggregateType = @"MTDocumentObjectDefinationAggregateType";
NSString * const MTDocumentObjectDefinationAggregatePivotNumber = @"MTDocumentObjectDefinationAggregatePivotNumber";
NSString * const MTDocumentObjectDefinationAggregatePivotType = @"MTDocumentObjectDefinationAggregatePivotType";
NSString * const MTDocumentObjectDefinationAggregateObjectId = @"MTDocumentObjectDefinationAggregateObjectId";
NSString * const MTDocumentObjectDefinationAggregateFunctionInputType = @"MTDocumentObjectDefinationAggregateFunctionInputType";

NSString * const MTDocumentObjectDefinationField1 = @"MTDocumentObjectDefinationField1";
NSString * const MTDocumentObjectDefinationField2 = @"MTDocumentObjectDefinationField2";

static NSNumberFormatter *currencyNumberFormatter;

//
//             Box model refresher
//
//  ..............................................
//  :                Margin                      :
//  :    ------------Border------------------    :
//  :    |           Padding                |    :
//  :    |                                  |    :
//  :    |  |----------------------------|  |    :
//  :    |  |     Inner Content          |  |    :
//  :    |  |----------------------------|  |    :
//  :    |                                  |    :
//  :    |           Padding                |    :
//  :    ------------Border------------------    :
//  :                Margin                      :
//  :.............................................
//
//

static inline CGFloat MADDocObjSizeWidthCalculated(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat);
static inline CGFloat MADDocObjSizeHeightCalculated(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat);
static inline CGRect MADDocObjFrameCalculated(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat);
static inline double paddingViewBoundsSizeHeight(double, double, double);
static inline double paddingViewBoundsSizeWidth(double, double, double);

static inline double paddingViewBoundsSizeHeight(double paddingTop, double paddingBottom, double sizeHeight) {
	return paddingTop + paddingBottom + sizeHeight;
}

static inline double paddingViewBoundsSizeWidth(double paddingLeft, double paddingRight, double sizeWidth) {
	return paddingLeft + paddingRight + sizeWidth;
}

static inline CGFloat MADDocObjSizeWidthCalculated(CGFloat paddingLeft, CGFloat borderWidthLeft, CGFloat marginLeft, CGFloat sizewidth, CGFloat marginRight, CGFloat borderWidthRight, CGFloat paddingRight) {
	return paddingLeft + borderWidthLeft + marginLeft + sizewidth + marginRight + borderWidthRight +
							paddingRight;
}

static inline CGFloat MADDocObjSizeHeightCalculated(CGFloat paddingTop, CGFloat borderHeightTop, CGFloat marginTop, CGFloat sizeheight, CGFloat marginBottom, CGFloat borderHeightBottom, CGFloat paddingBottom) {
	return paddingTop + borderHeightTop + marginTop + sizeheight + marginBottom + borderHeightBottom + paddingBottom;
}

static inline CGRect MADDocObjFrameCalculated(CGFloat x, CGFloat sx, CGFloat y, CGFloat sy, CGFloat w, CGFloat sw, CGFloat h, CGFloat wh) {
	return CGRectMake(x + sx, y + sy, w + sw, h + wh);
}

@implementation RptqDocumentElement (Extras)

#pragma mark -
#pragma mark Static Helpers

+ (void)load {
	if (self == [RptqDocumentElement class]) {
		NSString *c = NSStringFromClass([RptqDocumentElement class]);
		rptq_log = os_log_create("com.mad", c.UTF8String);
	}
}

+ (instancetype)newDocumentElementWithIdentifier:(int64_t)identifier
							   fromObjectContext:(NSManagedObjectContext *)context {
	NSFetchRequest <__kindof RptqDocumentElement *> *fetchRequet = [self fetchRequestElement: identifier];
	NSError *error = nil;
	NSArray <RptqDocumentElement *> *elements  = [context executeFetchRequest: fetchRequet error: &error];
	if (error != nil) {
		os_log_error(rptq_log, "Failed to fetch element with ID %lld: %{public}@", identifier, error.localizedDescription);
	}
	if (!elements.count) {
		os_log_debug(rptq_log, "No element found with ID %lld", identifier);
	}
	return elements.firstObject;
}

+ (void)removeDocumentObject:(RptqDocumentElement *)documentObject
		   fromParentSection:(RptqDocumentSection *)section
		   withLayoutManager:(MADSectionLayoutManager *)layoutManager {
	if (!documentObject || !section || !layoutManager) {
		os_log_error(rptq_log, "Invalid parameters in removeDocumentObject");
		return;
	}
	
	@try {
		RptqDocumentSectionRows *sectionRow = documentObject.inSectionRow;
		NSOrderedSet *sectionRowHasObjects =  documentObject.inSectionRow.hasObjects;
		NSUInteger deleteIndex = [sectionRowHasObjects indexOfObject:documentObject];
		if (deleteIndex == NSNotFound) {
			os_log_error(rptq_log, "Document object not found in section row");
			return;
		}
		
		NSMutableOrderedSet *hasObjects = documentObject.inSectionRow.hasObjects.mutableCopy;
		[hasObjects removeObjectAtIndex:deleteIndex];
		
		NSNumber *identifier = @(documentObject.identifier);
		[layoutManager removeItemWithID:identifier];
		[layoutManager layout];
		
		sectionRow.hasObjects = hasObjects;
		documentObject.inSectionRow = nil;
		section.height = (float)layoutManager.size.height;
	} @catch (NSException *exception) {
		os_log_error(rptq_log, "Exception in removeDocumentObject: %{public}@", exception.reason);
	}
}

#pragma mark -
#pragma mark Keys

+ (NSString *)keyCalculatedHeight { return @"calculatedHeight"; }

+ (NSString *)keyInSectionRow { return NSStringFromSelector(@selector(inSectionRow)); }

+ (NSString *)keyRowNumber {
	NSString *result = [self keyInSectionRow];
	result = [MADStringUtilities stringByAppendingPeriod: result];
	result = [result stringByAppendingString:NSStringFromSelector(@selector(rowNumber))];
	return result;
}

+ (NSString *)keyInSection {
	NSString *result = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(inSectionRow))];
	return [result stringByAppendingString: NSStringFromSelector(@selector(inSection))];
}

+ (NSString *)keySize {
	NSString *result = NSStringFromSelector(@selector(size));
	return result;
}

+ (NSString *)keyMargin {
	NSString *result = NSStringFromSelector(@selector(margin));
	return result;
}

+ (NSString *)keyPadding {
	NSString *result = NSStringFromSelector(@selector(padding));
	return result;
}

+ (NSString *)keyBorderWidthTop {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(border))];
		result = [result stringByAppendingString:NSStringFromSelector(@selector(width))];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:NSStringFromSelector(@selector(top))];
	}
	return key;
}

+ (NSString *)keyBorderWidthBottom {
	static NSString *key = nil;
	if (key == nil) {
		NSString *keyBottom = [RptqDirectionalAsymmetry keyBottom];
		NSString *result = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(border))];
		result = [result stringByAppendingString:NSStringFromSelector(@selector(width))];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyBottom];
	}
	return key;
}

+ (NSString *)keyBorderWidthLeft {
	static NSString *key = nil;
	if (key == nil) {
		NSString *keyLeft = [RptqDirectionalAsymmetry keyLeft];
		NSString *result = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(border))];
		result = [result stringByAppendingString:NSStringFromSelector(@selector(width))];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyLeft];
	}
	return key;
}

+ (NSString *)keyBorderWidthRight {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = NSStringFromSelector(@selector(border));
		NSString *keyRight = [RptqDirectionalAsymmetry keyRight];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		result = [result stringByAppendingString:NSStringFromSelector(@selector(width))];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyRight];
	}
	return key;
}

+ (NSString *)keyPaddingTop {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [self keyPadding];
		NSString *keyTop = [RptqDirectionalAsymmetry keyTop];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyTop];
	}
	return key;
}

+ (NSString *)keyPaddingBottom {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [self keyPadding];
		NSString *keyBottom = [RptqDirectionalAsymmetry keyBottom];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyBottom];
	}
	return key;
}

+ (NSString *)keyPaddingLeft {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [self keyPadding];
		NSString *keyLeft = [RptqDirectionalAsymmetry keyLeft];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyLeft];
	}
	return key;
}

+ (NSString *)keyPaddingRight {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [self keyPadding];
		NSString *keyRight = [RptqDirectionalAsymmetry keyRight];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyRight];
	}
	return key;
}

+ (NSString *)keyMarginTop {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [self keyMargin];
		NSString *keyTop = [RptqDirectionalAsymmetry keyTop];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyTop];
	}
	return key;
}

+ (NSString *)keyMarginBottom {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [self keyMargin];
		NSString *keyBottom = [RptqDirectionalAsymmetry keyBottom];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyBottom];
	}
	return key;
}

+ (NSString *)keyMarginLeft {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [self keyMargin];
		NSString *keyLeft = [RptqDirectionalAsymmetry keyLeft];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:keyLeft];
	}
	return key;
}

+ (NSString *)keyMarginRight {
	static NSString *key = nil;
	if (key == nil) {
		key = [[MADStringUtilities stringByAppendingPeriod: [self keyMargin]] stringByAppendingString:[RptqDirectionalAsymmetry keyRight]];
	}
	return key;
}

+ (NSString *)keyRectOriginY {
	static NSString *key = nil;
	if (key == nil) {
		key = [[MADStringUtilities stringByAppendingPeriod: [[MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(rect))] stringByAppendingString:NSStringFromSelector(@selector(origin))]] stringByAppendingString:NSStringFromSelector(@selector(y))];
	}
	return key;
}

+ (NSString *)keyRectOriginX {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(rect))];
		result = [result stringByAppendingString:NSStringFromSelector(@selector(origin))];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:NSStringFromSelector(@selector(x))];
	}
	return key;
}

+ (NSString *)keyRectSizeHeight {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(rect))];
		result = [result stringByAppendingString:NSStringFromSelector(@selector(size))];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString: NSStringFromSelector(@selector(height))];
	}
	return key;
}

+ (NSString *)keyRectSizeWidth {
	static NSString *key = nil;
	if (key == nil) {
		NSString *result = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(rect))];
		result = [result stringByAppendingString:NSStringFromSelector(@selector(size))];
		result = [MADStringUtilities stringByAppendingPeriod: result];
		key = [result stringByAppendingString:NSStringFromSelector(@selector(width))];
	}
	return key;
}

+ (NSFetchRequest <__kindof RptqDocumentElement *> *)fetchRequestElement:(int64_t)identifier {
	NSExpression *left = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(identifier))];
	NSExpression *right = [NSExpression expressionForConstantValue:@(identifier)];
	NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression: left
												   rightExpression: right
														  modifier: NSDirectPredicateModifier
															  type: NSEqualToPredicateOperatorType
														   options: 0];
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([self class])];
	request.predicate = predicate;
	request.fetchLimit = 1;
	request.resultType = NSManagedObjectResultType;
	request.includesSubentities = YES;
	request.includesPropertyValues = YES;
	return request;
}

+ (NSFetchRequest <NSDictionary *> *)fetchRequestSectionHeight:(NSManagedObjectID *)sectionID {

	NSPredicate *predicate = [self comparisonPredicateInSection:sectionID];
	NSExpression *addBorder = [NSExpression expressionForFunction: @"add:to:" arguments: @[
		[NSExpression expressionForKeyPath:[self keyBorderWidthTop]],
		[NSExpression expressionForKeyPath:[self keyBorderWidthBottom]]
	]];

	NSExpression *addPadding = [NSExpression expressionForFunction: @"add:to:" arguments: @[
		[NSExpression expressionForKeyPath:[self keyPaddingTop]],
		[NSExpression expressionForKeyPath:[self keyPaddingBottom]]
	]];

	NSExpression *addMargin = [NSExpression expressionForFunction: @"add:to:" arguments: @[
		[NSExpression expressionForKeyPath:[self keyMarginTop]],
		[NSExpression expressionForKeyPath:[self keyMarginBottom]]
	]];

	NSExpression *addRect = [NSExpression expressionForFunction: @"add:to:" arguments: @[
		[NSExpression expressionForKeyPath:[self keyRectOriginY]],
		[NSExpression expressionForKeyPath:[self keyRectSizeHeight]]
	]];

	NSExpression *addMarginRect = [NSExpression expressionForFunction: @"add:to:" arguments: @[addMargin, addRect]];
	NSExpression *addPaddingBorder = [NSExpression expressionForFunction: @"add:to:" arguments: @[addPadding, addBorder]];
	
	NSExpressionDescription *expressionSum = [[NSExpressionDescription alloc] init];
	expressionSum.name = [self keyCalculatedHeight];
	expressionSum.expression = [NSExpression expressionForFunction: @"add:to:" arguments: @[addMarginRect, addPaddingBorder]];
	expressionSum.expressionResultType = NSFloatAttributeType;
/*
	NSExpressionDescription *expressionMax = [[NSExpressionDescription alloc] init];
	expressionMax.name = @"keyMax";
	expressionMax.expression = [NSExpression expressionForFunction:@"max:" arguments:@[[self keyCalculatedHeight]]];
	expressionMax.expressionResultType = NSFloatAttributeType;
*/
	
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([self class])];
	request.predicate = predicate;
	request.resultType = NSDictionaryResultType;
	request.propertiesToFetch = @[expressionSum];
	return request;
}

/*
			 //Sample code for fetchRequestElementsInSection
			results = [managedObjectContext executeFetchRequest: fetchRequestElements
														  error: &error];
			
			NSString *keyBorderWidthBottom = [RptqDocumentElement keyBorderWidthBottom];
			NSString *keyBorderWidthTop = [RptqDocumentElement keyBorderWidthTop];
			NSString *keyPaddingTop = [RptqDocumentElement keyPaddingTop];
			NSString *keyPaddingBottom = [RptqDocumentElement keyPaddingBottom];
			NSString *keyMarginTop = [RptqDocumentElement keyMarginTop];
			NSString *keyMarginBottom = [RptqDocumentElement keyMarginBottom];
			NSString *keyRectOriginY = [RptqDocumentElement keyRectOriginY];
			NSString *keyRectSizeHeight = [RptqDocumentElement keyRectSizeHeight];
			
			NSNumber *borderWidthBottom, *borderWidthTop, *paddingTop, *paddingBottom,
			*marginTop, *marginBottom, *originY, *sizeHeight;
			for (NSDictionary *result in results) {
				borderWidthBottom = result[keyBorderWidthBottom];
				borderWidthTop = result[keyBorderWidthTop];
				paddingBottom = result[keyPaddingBottom];
				paddingTop = result[keyPaddingTop];
				marginBottom = result[keyMarginBottom];
				marginTop = result[keyMarginTop];
				originY = result[keyRectOriginY];
				sizeHeight = result[keyRectSizeHeight];
				
				height = MAX(height,
							 borderWidthBottom.floatValue + borderWidthTop.floatValue +
							 paddingBottom.floatValue + paddingTop.floatValue +
							 marginBottom.floatValue + marginTop.floatValue +
							 originY.floatValue + sizeHeight.floatValue);
			}

 */

+ (NSFetchRequest <NSDictionary *> *)fetchRequestElementsInSection:(NSManagedObjectID *)sectionID {

	NSPredicate *predicate = [self comparisonPredicateInSection:sectionID];

	NSExpressionDescription *expressionSelf = [[NSExpressionDescription alloc] init];
	expressionSelf.name = NSStringFromSelector(@selector(self));
	expressionSelf.expression = [NSExpression expressionForEvaluatedObject];
	expressionSelf.expressionResultType = NSObjectIDAttributeType;

	predicate = [self comparisonPredicateInSection:sectionID];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([self class])];
	request.predicate = predicate;
	request.resultType = NSDictionaryResultType;
	
	NSString *keyBorderWidthTop = [self keyBorderWidthTop];
	NSString *keyBorderWidthBottom = [self keyBorderWidthBottom];
	NSString *keyPaddingTop = [self keyPaddingTop];
	NSString *keyPaddingBottom = [self keyPaddingBottom];
	NSString *keyMarginTop = [self keyMarginTop];
	NSString *keyMarginBottom = [self keyMarginBottom];
	NSString *keyRectOriginY = [self keyRectOriginY];
	NSString *keyRectSizeHeight = [self keyRectSizeHeight];
	
	request.propertiesToFetch = @[expressionSelf, keyBorderWidthTop, keyBorderWidthBottom, keyPaddingTop, keyPaddingBottom, keyMarginTop, keyMarginBottom, keyRectOriginY, keyRectSizeHeight];
	
	return request;
}

+ (NSFetchRequest <NSDictionary *> *)fetchRequestElementsInSectionDetailed:(NSManagedObjectID *)sectionID {
	NSFetchRequest *request;
	NSPredicate *predicate = [self comparisonPredicateInSection:sectionID];
	
	NSString *keySelf = NSStringFromSelector(@selector(self));
	
	NSExpressionDescription *expressionSelf = [[NSExpressionDescription alloc] init];
	expressionSelf.name = keySelf;
	expressionSelf.expression = [NSExpression expressionForEvaluatedObject];
	expressionSelf.expressionResultType = NSObjectIDAttributeType;
	
	NSString *entityName = NSStringFromClass([self class]);
	request = [[NSFetchRequest alloc] initWithEntityName: entityName];
	request.predicate = predicate;
	request.resultType = NSDictionaryResultType;
	
	NSString *keyBorderWidthTop = [self keyBorderWidthTop];
	NSString *keyBorderWidthBottom = [self keyBorderWidthBottom];
	NSString *keyBorderWidthLeft = [self keyBorderWidthLeft];
	NSString *keyBorderWidthRight = [self keyBorderWidthRight];
	NSString *keyPaddingTop = [self keyPaddingTop];
	NSString *keyPaddingBottom = [self keyPaddingBottom];
	NSString *keyPaddingLeft = [self keyPaddingLeft];
	NSString *keyPaddingRight = [self keyPaddingRight];
	NSString *keyMarginTop = [self keyMarginTop];
	NSString *keyMarginBottom = [self keyMarginBottom];
	NSString *keyMarginLeft = [self keyMarginLeft];
	NSString *keyMarginRight = [self keyMarginRight];
	NSString *keyRectOriginY = [self keyRectOriginY];
	NSString *keyRectOriginX = [self keyRectOriginX];
	NSString *keyRectSizeHeight = [self keyRectSizeHeight];
	NSString *keyRectSizeWidth = [self keyRectSizeWidth];
	NSString *keyRowNumber = [self keyRowNumber];
	
	NSArray *propertiesToFetch = [[NSArray alloc] initWithObjects: expressionSelf,
								  keyBorderWidthTop, keyBorderWidthBottom,
								  keyBorderWidthLeft, keyBorderWidthRight,
								  keyPaddingTop, keyPaddingBottom,
								  keyPaddingLeft, keyPaddingRight,
								  keyMarginTop, keyMarginBottom,
								  keyMarginLeft, keyMarginRight,
								  keyRectOriginX, keyRectOriginY,
								  keyRectSizeHeight, keyRectSizeWidth,
								  keyRowNumber, nil];
	request.propertiesToFetch = propertiesToFetch;
	
	return request;
}

+ (NSPredicate *)comparisonPredicateInSection:(NSManagedObjectID *)sectionID {
	NSString *keyInSection = [self keyInSection];
	NSExpression *left, *right;
	left = [NSExpression expressionForKeyPath:keyInSection];
	right = [NSExpression expressionForConstantValue:sectionID];
	return [NSComparisonPredicate predicateWithLeftExpression: left
											  rightExpression: right
													 modifier: NSDirectPredicateModifier
														 type: NSEqualToPredicateOperatorType
													  options: 0];
}

#pragma mark -
#pragma mark Overrides

- (void)awakeFromInsert {
	[super awakeFromInsert];
	
	// MARK: Auto increment row counter
	NSFetchRequest *request;
	NSString *entityNameSelf = NSStringFromClass([RptqDocumentElement class]);
	NSString *key = NSStringFromSelector(@selector(identifier));
	
	request = [[NSFetchRequest alloc] initWithEntityName: entityNameSelf];

	NSSortDescriptor *sortDescriptor;
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key ascending: NO];
	
	id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
	request.sortDescriptors = sortDescriptors;
	request.fetchLimit = 1;
	NSString *keyDropIndex = NSStringFromSelector(@selector(dropIndex));
	NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
	
	NSExpressionDescription *edIdentifier, *edLastObject;
	edIdentifier = [[NSExpressionDescription alloc] init];
	edIdentifier.name = keyIdentifier;
	edIdentifier.expression = [NSExpression expressionForKeyPath:keyIdentifier];
	edIdentifier.expressionResultType = NSInteger64AttributeType;

	edLastObject = [[NSExpressionDescription alloc] init];
	edLastObject.name = keyDropIndex;
	edLastObject.expression = [NSExpression expressionForKeyPath:keyDropIndex];
	edLastObject.expressionResultType = NSInteger64AttributeType;

	request.propertiesToFetch = @[edIdentifier, edLastObject];
	request.resultType = NSDictionaryResultType;

	NSError *error = nil;
	NSArray <NSDictionary *> *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
	
	if (error != nil) {
		os_log_error(rptq_log, "Error: %@", error);
	}
	
	if (self.alignment == nil) {
		NSString *name = NSStringFromClass([RptqAlignment class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.alignment = [NSEntityDescription insertNewObjectForEntityForName:name
													   inManagedObjectContext:managedObjectContext];
	}
	if (self.border == nil) {
		NSString *name = NSStringFromClass([RptqBorder class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.border = [NSEntityDescription insertNewObjectForEntityForName:name
													inManagedObjectContext:managedObjectContext];
	}
	if (self.dropPoint == nil) {
		NSString *name = NSStringFromClass([RptqPoint class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.dropPoint = [NSEntityDescription insertNewObjectForEntityForName:name
													   inManagedObjectContext:managedObjectContext];
	}
	
	if (self.margin == nil) {
		NSString *name = NSStringFromClass([RptqDirectionalAsymmetry class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.margin = [NSEntityDescription insertNewObjectForEntityForName:name
													   inManagedObjectContext:managedObjectContext];
	}
	
	if (self.numericFormat == nil) {
		NSString *name = NSStringFromClass([RptqNumericFormat class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.numericFormat = [NSEntityDescription insertNewObjectForEntityForName:name
													   inManagedObjectContext:managedObjectContext];
	}
	if (self.padding == nil) {
		NSString *name = NSStringFromClass([RptqDirectionalAsymmetry class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.padding = [NSEntityDescription insertNewObjectForEntityForName:name
													   inManagedObjectContext:managedObjectContext];
	}
	if (self.rect == nil) {
		NSString *name = NSStringFromClass([RptqRect class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.rect = [NSEntityDescription insertNewObjectForEntityForName:name
													   inManagedObjectContext:managedObjectContext];
	}
	if (self.textStyle == nil) {
		NSString *name = NSStringFromClass([RptqTextStyle class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.textStyle = [NSEntityDescription insertNewObjectForEntityForName:name
													   inManagedObjectContext:managedObjectContext];
		//self.updated = YES;
	}
	
	int64_t idNumber = 0;
	int64_t lastDropIndex = 0;
	if (fetchResults.count) {

		NSDictionary <NSString *, NSNumber *> *lastObject = fetchResults.lastObject;

		
		CFNumberGetValue((__bridge CFNumberRef)(lastObject[keyIdentifier]), kCFNumberSInt64Type, &idNumber);
		CFNumberGetValue((__bridge CFNumberRef)(lastObject[keyDropIndex]), kCFNumberSInt64Type, &lastDropIndex);

		idNumber++;
		lastDropIndex++;
	}
	
	self.fontname = [MADFont defaultFamily];
	self.fontsize = [MADFont defaultSize];
	self.identifier = idNumber;
	self.dropIndex = lastDropIndex;
	
}

- (BOOL)validateForInsert:(NSError * __autoreleasing *)error {
	BOOL success;
	NSError * __autoreleasing errorValidation = nil;
	if (!(success = [super validateForInsert:&errorValidation])) {
		if (error != NULL) { // Check if error is not NULL before dereferencing
			*error = errorValidation.copy; // Copy the error to outError
		}
		os_log_error(rptq_log, "Error: %s", errorValidation.localizedDescription.UTF8String);
	}
	return success;
}

- (void)setSizeWidth:(float)width {
	self.rect.size.width = width;
}

- (void)setSizeHeight:(float)height {
	self.rect.size.height = height;
}

- (void)setHorizontalAlignment:(MADHorizontalAlignment)alignment {
	self.alignment.horizontal = alignment;
}

- (void)setVerticalAlignment:(MADVerticalAlignment)alignment {
	self.alignment.vertical = alignment;
}

- (CGPoint)placementPoint {
	CGPoint placementPoint = [(NSValue *)self.dropPoint CGPointValue];
	return placementPoint;
}

- (void)setSizeWidth:(float)w height:(float)h {
	self.rect.size.width = w;
	self.rect.size.height = h;
}

- (void)setSizeValue:(CGSize)size {
	self.rect.size.width = (float)size.width;
	self.rect.size.height = (float)size.height;
}

- (void)setOriginPoint:(CGPoint)or {
	self.rect.origin.x = (float)or.x;
	self.rect.origin.y = (float)or.y;
}

- (double)spacingLeft {
	return self.margin.left + self.border.width.left + self.padding.left;
}

- (double)spacingRight {
	return self.margin.right + self.border.width.right + self.padding.right;
}

- (double)spacingTop {
	return self.margin.top + self.border.width.top + self.padding.top;
}

- (double)spacingBottom {
	return self.margin.bottom + self.border.width.bottom + self.padding.bottom;
}

- (CGFloat)sizeWidthCalculated {
	return MADDocObjSizeWidthCalculated(self.padding.left,
										self.border.width.left,
										self.margin.left,
										self.rect.size.width,
										self.margin.right,
										self.border.width.right,
										self.padding.right);
}

- (CGFloat)sizeHeightCalculated {
	return MADDocObjSizeHeightCalculated(self.padding.top,
										 self.border.width.top,
										 self.margin.top,
										 self.rect.size.height,
										 self.margin.bottom,
										 self.border.width.bottom,
										 self.padding.bottom);
}

- (CGSize)innerSize {
	return CGSizeMake(self.rect.size.width, self.rect.size.height);
}

- (CGSize)sizeCalculated {
	CGFloat width = MADDocObjSizeWidthCalculated(self.padding.left,
												 self.border.width.left,
												 self.margin.left,
												 self.rect.size.width,
												 self.margin.right,
												 self.border.width.right,
												 self.padding.right);
	CGFloat height = MADDocObjSizeHeightCalculated(self.padding.top,
												   self.border.width.top,
												   self.margin.top,
												   self.rect.size.height,
												   self.margin.bottom,
												   self.border.width.bottom,
												   self.padding.bottom);
	return CGSizeMake(width, height);
}

- (CGRect)boundsCalculated {
	CGFloat width = MADDocObjSizeWidthCalculated(self.padding.left,
												 self.border.width.left,
												 self.margin.left,
												 self.rect.size.width,
												 self.margin.right,
												 self.border.width.right,
												 self.padding.right);
	CGFloat height = MADDocObjSizeHeightCalculated(self.padding.top,
												   self.border.width.top,
												   self.margin.top,
												   self.rect.size.height,
												   self.margin.bottom,
												   self.border.width.bottom,
												   self.padding.bottom);
	return CGRectMake(CGPointZero.x, CGPointZero.y, width, height);
}

- (CGSize)sizeContentView {
	return CGSizeMake(self.rect.size.width, self.rect.size.height);
}

- (CGRect)boundsContentView {
	return CGRectMake(CGPointZero.x, CGPointZero.y, self.rect.size.width, self.rect.size.height);
}

- (CGRect)paddingViewBounds {
	double w = paddingViewBoundsSizeWidth(self.padding.left,
										  self.padding.right,
										  self.rect.size.width);
	double h = paddingViewBoundsSizeHeight(self.padding.top,
										   self.padding.bottom,
										   self.rect.size.height);
	return CGRectMake(CGPointZero.x, CGPointZero.y, w, h);
}

- (CGRect)paddingViewFrame {
	CGRect paddingViewBounds = [self paddingViewBounds];
	return CGRectMake(CGPointZero.x + self.margin.left,
					  CGPointZero.y + self.margin.top,
					  paddingViewBounds.size.width, paddingViewBounds.size.height);
}

- (CGRect)elementViewBounds {
	return CGRectMake(CGPointZero.x, CGPointZero.y, self.rect.size.width, self.rect.size.height);
}

- (CGRect)elementViewFrameDesignerFrameCalculated {
	return CGRectMake(self.rect.origin.x, self.rect.origin.y, self.rect.size.width, self.rect.size.height);
}

- (CGRect)elementViewFrameDesigner {
	return CGRectMake(self.rect.origin.x, self.rect.origin.y, self.rect.size.width, self.rect.size.height);
}

- (CGRect)frame {
	return MADDocObjFrameCalculated(self.rect.origin.x, self.spacingLeft,
									self.rect.origin.y, self.spacingTop,
									self.rect.size.width, self.spacingRight,
									self.rect.size.height, self.spacingBottom);
}

- (CGRect)elementViewFrame {
	return CGRectMake(self.rect.origin.x,
					  self.rect.origin.y,
					  self.rect.size.width + self.margin.left + self.margin.right + self.border.width.left + self.border.width.right + self.padding.left + self.padding.right,
					  self.rect.size.height + self.margin.top + self.margin.bottom + self.border.width.top + self.border.width.bottom + self.padding.top + self.padding.bottom);
}

//For lines in box model, each x and y coordnate for the point pairs needed to make up the line.

- (CGFloat)borderLineTopAX {
	return CGPointZero.x + self.margin.left;
}

- (CGFloat)borderLineTopAY {
	return CGPointZero.y + self.margin.top;
}
- (CGFloat)borderLineTopBX {
	return CGPointZero.x + self.margin.left + self.border.width.left + self.padding.left +
		self.rect.size.width + self.padding.right + self.border.width.right;
}

- (CGFloat)borderLineTopBY {
	return CGPointZero.y + self.margin.top;
}

- (CGFloat)borderLineBottomAX {
	return CGPointZero.x + self.margin.left;
}

- (CGFloat)borderLineBottomAY {
	return CGPointZero.y + self.margin.top + self.border.width.top + self.padding.top +
		self.rect.size.height + self.padding.bottom + self.border.width.bottom;
}
- (CGFloat)borderLineBottomBX {
	return CGPointZero.x + self.margin.left + self.border.width.left + self.padding.left +
		self.rect.size.width + self.padding.right + self.border.width.right;
}

- (CGFloat)borderLineBottomBY {
	return CGPointZero.y + self.margin.top + self.border.width.top + self.padding.top +
		self.rect.size.height + self.padding.bottom + self.border.width.bottom;
}

- (CGFloat)borderLineLeftAX {
	return [self borderLineTopAX];
}

- (CGFloat)borderLineLeftAY {
	return [self borderLineTopAY];
}
- (CGFloat)borderLineLeftBX {
	return [self borderLineBottomAX];
}

- (CGFloat)borderLineLeftBY {
	return [self borderLineBottomAY];
}
- (CGFloat)borderLineRightAX {
	return [self borderLineTopBX];
}

- (CGFloat)borderLineRightAY {
	return [self borderLineTopBY];
}

- (CGFloat)borderLineRightBX {
	return [self borderLineBottomBX];
}

- (CGFloat)borderLineRightBY {
	return [self borderLineBottomBY];
}

- (CGRect)borderRect {
	return CGRectMake(CGPointZero.x + self.margin.left,
					  CGPointZero.y + self.margin.top,
					  self.rect.size.width + self.border.width.left + self.border.width.right + self.padding.left + self.padding.right,
					  self.rect.size.height + self.border.width.top + self.border.width.bottom + self.padding.top + self.padding.bottom);
}

- (CGRect)paddingRect {
	return CGRectMake(CGPointZero.x + self.margin.left + self.border.width.left,
					  CGPointZero.y + self.margin.top + self.border.width.top,
					  self.rect.size.width + self.padding.left + self.padding.right,
					  self.rect.size.height + self.padding.top + self.padding.bottom);
}

- (CGRect)innerRect {
	return CGRectMake(CGPointZero.x + self.margin.left + self.border.width.left + self.padding.left,
					  CGPointZero.y + self.margin.top + self.border.width.top + self.padding.top,
					  self.rect.size.width,
					  self.rect.size.height);
}

#pragma mark - Member

- (MADPrintPageElementType)documentObjectType {
	return self.type;
}

- (NSString *)designerRepresentationText {
	if (self.documentObjectType == MADPrintPageElementTypeWhtiespace) {
		return @"";
	}
	@throw NSInternalInconsistencyException;
}

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
	// NSNull is how a NULL read from a source database arrives here -- it is not nil,
	// so it used to fall through to the branches below, whose text paths all end in
	// -initWithFormat:@"%@", which writes NSNull as "<null>".  That is what appeared
	// on the report.  The date branches were worse: NSNull is not NSData, NSString or
	// NSNumber, so the interval defaulted to 0 and a NULL date printed as the epoch.
	// A NULL has no representation, so it is empty at the source instead.
	if (!value || [value isKindOfClass:[NSNull class]]) {
		return @"";
	}

	NSString *result = nil;

	switch (dataType) {
	
		case MADDataTypeYear:
			if ([value isKindOfClass:[NSString class]]) {
				result = value;
			} else if ([value isKindOfClass:[NSNumber class]]) {
				result = [[NSString alloc] initWithFormat:@"%ld", (long)((NSNumber *)value).integerValue];
			} else {
				result = [[NSString alloc] initWithFormat:@"%@", value];
			}
			break;
			
		case MADDataTypeGeometry:
			result = [[NSString alloc] initWithFormat:@"%@", value];
			break;
			
		case MADDataTypeImage:
			result = [[NSString alloc] initWithFormat:@"%@", value];
			break;
			
		case MADDataTypeSet:
			result = [[NSString alloc] initWithFormat:@"%@", value];
			break;
			
		case MADDataTypeUnknown:
			result = [[NSString alloc] initWithFormat:@"%@", value];
			break;
			
		case MADDataTypeDate:
		case MADDataTypeDateTime:
		case MADDataTypeTime:
		case MADDataTypeTimeStamp: {
			static NSDateFormatter *dateformatter;
			static NSDateFormatter *timeformatter;
			static NSDateFormatter *dateTimeformatter;
			if (dateformatter == nil) {
				dateformatter = [[NSDateFormatter alloc] init];
				dateformatter.dateStyle = NSDateFormatterShortStyle;
				dateformatter.timeStyle = NSDateFormatterNoStyle;
			}
			if (timeformatter == nil) {
				timeformatter = [[NSDateFormatter alloc] init];
				timeformatter.dateStyle = NSDateFormatterNoStyle;
				timeformatter.timeStyle = NSDateFormatterShortStyle;
			}
			if (dateTimeformatter == nil) {
				dateTimeformatter = [[NSDateFormatter alloc] init];
				dateTimeformatter.dateStyle = NSDateFormatterShortStyle;
				dateTimeformatter.timeStyle = NSDateFormatterShortStyle;
			}
			NSDate *d = nil;
			if ([value isKindOfClass:[NSData class]]) {
				d = value;
			} else {
				NSTimeInterval t = 0;
				if ([value isKindOfClass:[NSString class]]) {
					t = ((NSString *)value).longLongValue;
				} else if ([value isKindOfClass:[NSNumber class]]) {
					t = [value longLongValue];
				}
				d = [NSDate dateWithTimeIntervalSince1970:t];
			}
			switch (dataType) {
				case MADDataTypeDate:
					result = [dateformatter stringFromDate:d];
					break;
				case MADDataTypeDateTime:
					result = [dateTimeformatter stringFromDate:d];
					break;
				case MADDataTypeTime:
					result = [timeformatter stringFromDate:d];
					break;
					
				case MADDataTypeTimeStamp:
					result = [dateformatter stringFromDate:d];
					break;

				default:
					result = [[NSString alloc] initWithFormat:@"%@", value];
					break;
			}
  
			break;
		}
		
		case MADDataTypeBlob:
			result = [[NSString alloc] initWithFormat:@"%@", value];
			break;
			
		case MADDataTypeBit:
		case MADDataTypeFloat:
		case MADDataTypeInteger:
		case MADDataTypeLong:
		case MADDataTypeLongLong:
		case MADDataTypeInt24:
		case MADDataTypeEnum:
		case MADDataTypeDouble:
		case MADDataTypeDecimal:
		case MADDataTypeNumber:
		{
			if ([value isKindOfClass:[NSNumber class]]) {
				
				if (((MADCurrencyFormatter *)self.numericFormat).enabled) {
					if (!currencyNumberFormatter) {
						currencyNumberFormatter = [[NSNumberFormatter alloc] init];
						currencyNumberFormatter.locale = [NSLocale currentLocale];
						currencyNumberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
					}
					result = [currencyNumberFormatter stringFromNumber:value];
				} else {
					NSMutableString *format;
					format = [[NSMutableString alloc] initWithString:@"%."];
					[format appendFormat:@"%lld", self.numericFormat.decimalCount];
					[format appendString:@"f"];
					result = [[NSString alloc] initWithFormat:format, [value floatValue]];
				}
			} else {
				result = [[NSString alloc] initWithFormat:@"%@", value];
			}
			break;
		}
		case MADDataTypeString:
			result = [[NSString alloc] initWithFormat:@"%@", value];
			break;
		default:
			result = [[NSString alloc] initWithFormat:@"%@", value];
			break;
	}
	if (result == nil) {
		result = @"";
	}
	return result;
}

#pragma mark -
#pragma mark MTProtocolLog

- (NSString *)toString {
	return [self toStringDebug];
}

- (NSString *)toStringDebug {
	return [[NSString alloc] initWithFormat: @"%@-%@", self, [self designerRepresentationText]];
}

- (NSString *)toStringHumanReadable {
	return [self designerRepresentationText];
}

- (NSAttributedString *)toAttributedString {
	return nil;
}

- (NSString *)debugDescriptionType {
	switch (self.type) {
		case MADPrintPageElementTypeAggregate:
			return @"Aggregate";
			break;
			
		case MADPrintPageElementTypeChart:
			return @"Chart";
			break;
			
		case MADPrintPageElementTypeFormula:
			return @"Formula";
			break;
			
		case MADPrintPageElementTypeGroupKey:
			return @"Group Key";
			break;

		case MADPrintPageElementTypeImage:
			return @"Image";
			break;
			
		case MADPrintPageElementTypeLabelDynamic:
			return @"Dynamic";
			break;
			
		case MADPrintPageElementTypeLabelStatic:
			return @"Static";
			break;
			
		case MADPrintPageElementTypeWhtiespace:
			return @"Whitespace";
			break;
			
		case MADPrintPageElementTypeBarcode:
			return @"Barcode";
			break;

		default:
			return @"Unknown";
			break;
	}
}

- (UIFontDescriptor *)fontDescriptor {
	UIFontDescriptorSymbolicTraits traits = 0;
	if (self.textStyle.italic) traits     |= UIFontDescriptorTraitItalic;
	if (self.textStyle.bold)   traits     |= UIFontDescriptorTraitBold;
	
	NSDictionary *fontAttributes = @{
		UIFontDescriptorFamilyAttribute: self.fontname ?: [MADFont defaultFamily],
		UIFontDescriptorSizeAttribute: @(self.fontsize),
		UIFontDescriptorTraitsAttribute: @{UIFontSymbolicTrait: @(traits)}
	};
	
	return [[UIFontDescriptor alloc] initWithFontAttributes:fontAttributes];
}


- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********\n"];
	[description appendFormat:@"ID:  \t\t%lld (%@)\n", self.identifier, self.debugDescriptionType];
	[description appendFormat:@"Sec: \t\t%@\n", [self.inSectionRow.inSection localizedDisplayName]];
	[description appendFormat:@"Font:\t\t%@ (%f)\n", self.fontname, self.fontsize];
	[description appendFormat:@"*********"];
	return description;
}

@end
