//
//  MADElementMigrationPolicy.m
//  MAD Designer
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADElementMigrationPolicy.h"
#import <MADFoundation/madlog.h>

#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqRect.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/RptqSize.h>
#import <MAD/RptqNumericFormat.h>
#import <MAD/RptqPoint.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqDirectionalProperty.h>

#import <MAD/MADAlignment.h>
#import <MAD/MADCurrencyFormatter.h>

#import <MADCocoaExtensions/MADBorderStyle.h>
#import <MADCocoaExtensions/MADMargin.h>
#import <MADCocoaExtensions/MADPadding.h>
#import <MADCocoaExtensions/MADTextStyle.h>

#import <UIKit/UIGeometry.h>
#import <UIKit/UIColor.h>

@implementation MADElementMigrationManager

- (NSArray<__kindof NSManagedObject *> *)destinationInstancesForEntityMappingNamed:(NSString *)mappingName
																   sourceInstances:(NSArray<__kindof NSManagedObject *> *)sourceInstances {
	NSArray <__kindof NSManagedObject *> *results = [super destinationInstancesForEntityMappingNamed: mappingName
																					 sourceInstances: sourceInstances];
	return results;
}

@end

@implementation MADElementMigrationPolicy

- (void)addBorderToElement:(RptqDocumentElement *)destinationElement
			   fromElement:(NSManagedObject *)sourceElement
				forContext:(NSManagedObjectContext *)context {

	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqBorder class])
														 inManagedObjectContext: context];
	RptqBorder *border = (RptqBorder *)[[NSManagedObject alloc] initWithEntity: entityDescription
												insertIntoManagedObjectContext: context];
	
	NSEntityDescription *entityDescriptionDirection = [NSEntityDescription entityForName: NSStringFromClass([RptqDirectionalProperty class])
																  inManagedObjectContext: context];
	RptqDirectionalProperty *style = (RptqDirectionalProperty *)[[NSManagedObject alloc] initWithEntity: entityDescriptionDirection
																		 insertIntoManagedObjectContext: context];

	NSEntityDescription *entityDescriptionAsy = [NSEntityDescription entityForName: NSStringFromClass([RptqDirectionalAsymmetry class])
															inManagedObjectContext: context];
	RptqDirectionalAsymmetry *width = (RptqDirectionalAsymmetry *)[[NSManagedObject alloc] initWithEntity: entityDescriptionAsy
																		   insertIntoManagedObjectContext: context];

	NSNumber *n = [sourceElement valueForKey:@"borderHeightTop"];
	if (n != nil) [width setValue:n forKey:@"top"];
	
	n = [sourceElement valueForKey:@"borderHeightBottom"];
	if (n != nil) [width setValue:n forKey:@"bottom"];
	
	n = [sourceElement valueForKey:@"borderWidthLeft"];
	if (n != nil) [width setValue:n forKey:@"left"];
	
	n = [sourceElement valueForKey:@"borderWidthRight"];
	if (n != nil) [width setValue:n forKey:@"right"];

	n = [sourceElement valueForKey:@"borderStyleTop"];
	if (n != nil) [style setValue:n forKey:@"top"];
	
	n = [sourceElement valueForKey:@"borderStyleBottom"];
	if (n != nil) [style setValue:n forKey:@"bottom"];
	
	n = [sourceElement valueForKey:@"borderStyleLeft"];
	if (n != nil) [style setValue:n forKey:@"left"];

	n = [sourceElement valueForKey:@"borderStyleRight"];
	if (n != nil) [style setValue:n forKey:@"right"];
	
	border.width = width;
	border.style = style;
	destinationElement.border = border;

}

- (void)addPaddingToElement:(RptqDocumentElement *)destinationElement
				fromElement:(NSManagedObject *)sourceElement
				 forContext:(NSManagedObjectContext *)context {
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqDirectionalAsymmetry class])
														 inManagedObjectContext: context];
	RptqDirectionalAsymmetry *padding = (RptqDirectionalAsymmetry *)[[NSManagedObject alloc] initWithEntity: entityDescription
																			 insertIntoManagedObjectContext: context];
	
	NSNumber *n = [sourceElement valueForKey:@"paddingBottom"];
	if (n != nil) [padding setValue:n forKey:@"bottom"];
	
	n = [sourceElement valueForKey:@"paddingLeft"];
	if (n != nil) [padding setValue:n forKey:@"left"];
	
	n = [sourceElement valueForKey:@"paddingRight"];
	if (n != nil) [padding setValue:n forKey:@"right"];
	
	n = [sourceElement valueForKey:@"paddingTop"];
	if (n != nil) [padding setValue:n forKey:@"top"];
	
	destinationElement.padding = padding;

	RptqDirectionalAsymmetry *margin = (RptqDirectionalAsymmetry *)[[NSManagedObject alloc] initWithEntity: entityDescription
																			insertIntoManagedObjectContext: context];
	
	n = [sourceElement valueForKey:@"marginBottom"];
	if (n != nil) [margin setValue:n forKey:@"bottom"];
	
	n = [sourceElement valueForKey:@"marginLeft"];
	if (n != nil) [margin setValue:n forKey:@"left"];
	
	n = [sourceElement valueForKey:@"marginRight"];
	if (n != nil) [margin setValue:n forKey:@"right"];
	
	n = [sourceElement valueForKey:@"marginTop"];
	if (n != nil) [margin setValue:n forKey:@"top"];
	
	destinationElement.margin = margin;
}

- (void)addRectToElement:(RptqDocumentElement *)destinationElement
			 fromElement:(NSManagedObject *)sourceElement
			  forContext:(NSManagedObjectContext *)context {
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqRect class])
														 inManagedObjectContext: context];

	RptqRect *rect = (RptqRect *)[[NSManagedObject alloc] initWithEntity: entityDescription
										  insertIntoManagedObjectContext: context];

	entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqPoint class])
									inManagedObjectContext: context];

	RptqPoint *origin = (RptqPoint *)[[NSManagedObject alloc] initWithEntity: entityDescription
											  insertIntoManagedObjectContext: context];

	entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqSize class])
									inManagedObjectContext: context];

	RptqSize *size = (RptqSize *)[[NSManagedObject alloc] initWithEntity: entityDescription
										  insertIntoManagedObjectContext: context];

	NSNumber *n = [sourceElement valueForKey:@"originx"];
	if (n != nil) [origin setValue:n forKey:@"x"];

	n = [sourceElement valueForKey:@"originy"];
	if (n != nil) [origin setValue:n forKey:@"y"];
	
	n = [sourceElement valueForKey:@"sizewidth"];
	if (n != nil) [size setValue:n forKey:@"width"];

	n = [sourceElement valueForKey:@"sizeheight"];
	if (n != nil) [size setValue:n forKey:@"height"];

	rect.origin = origin;
	rect.size = size;
	destinationElement.rect = rect;
}

- (void)addNumericFormatToElement:(RptqDocumentElement *)destinationElement
					  fromElement:(NSManagedObject *)sourceElement
					   forContext:(NSManagedObjectContext *)context {
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqNumericFormat class])
														 inManagedObjectContext: context];
	RptqNumericFormat *numericFormat = (RptqNumericFormat *)[[NSManagedObject alloc] initWithEntity: entityDescription
																	 insertIntoManagedObjectContext: context];
	
	NSNumber *n = [sourceElement valueForKey:@"formatNumericDecimals"];
	if (n != nil) [numericFormat setValue:n forKey:@"decimalCount"];
	
	n = [sourceElement valueForKey:@"formatNumericCurrency"];
	if (n != nil) [numericFormat setValue:n forKey:@"enabled"];
	
	NSString *currencyLocale = [sourceElement valueForKey:@"formatNumericCurrencyLocal"];
	if (currencyLocale != nil) {
		NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:currencyLocale];
		if (locale != nil) [numericFormat setValue:locale forKey:@"locale"];
	}
	destinationElement.numericFormat = numericFormat;

}

- (void)addAlignmentToElement:(RptqDocumentElement *)destinationElement
				  fromElement:(NSManagedObject *)sourceElement
				   forContext:(NSManagedObjectContext *)context {
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqAlignment class])
														 inManagedObjectContext: context];
	RptqAlignment *alignment = (RptqAlignment *)[[NSManagedObject alloc] initWithEntity: entityDescription
														 insertIntoManagedObjectContext: context];;
	
	NSNumber *n = [sourceElement valueForKey:@"horizontalAlignment"];
	if (n != nil) [alignment setValue:n forKey:@"horizontal"];
	
	n = [sourceElement valueForKey:@"verticalAlignment"];
	if (n != nil) [alignment setValue:n forKey:@"vertical"];
	
	destinationElement.alignment = alignment;
}

- (void)addTextStyleToElement:(RptqDocumentElement *)destinationElement
				  fromElement:(NSManagedObject *)sourceElement
				   forContext:(NSManagedObjectContext *)context {
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqTextStyle class])
														 inManagedObjectContext: context];
	RptqTextStyle *textStyle = (RptqTextStyle *)[[NSManagedObject alloc] initWithEntity: entityDescription
														 insertIntoManagedObjectContext: context];
	
	NSNumber *n = [sourceElement valueForKey:@"underline"];
	if (n != nil) [textStyle setValue:n forKey:@"underline"];
	
	n = [sourceElement valueForKey:@"bold"];
	if (n != nil) [textStyle setValue:n forKey:@"bold"];
	
	n = [sourceElement valueForKey:@"strike"];
	if (n != nil) [textStyle setValue:n forKey:@"strikethrough"];
	
	n = [sourceElement valueForKey:@"italic"];
	if (n != nil) [textStyle setValue:n forKey:@"italic"];

	destinationElement.textStyle = textStyle;

}

- (void)addPointToElement:(RptqDocumentElement *)destinationElement
			  fromElement:(NSManagedObject *)sourceElement
			   forContext:(NSManagedObjectContext *)context {
	
	NSEntityDescription *entityDescription;
	NSString *key = NSStringFromClass([RptqPoint class]);
	entityDescription = [NSEntityDescription entityForName: key
									inManagedObjectContext: context];
	RptqPoint *point = (RptqPoint *)[[NSManagedObject alloc] initWithEntity: entityDescription
											 insertIntoManagedObjectContext: context];
	
	NSNumber *n;
	key = NSStringFromClass([RptqPoint class]);	// Value stored to 'key' is never read
	n = [sourceElement valueForKey:@"dropPointX"];
	if (n != nil) [point setValue: n forKey:@"x"];
	
	n = [sourceElement valueForKey:@"dropPointY"];
	if (n != nil) [point setValue: n forKey:@"y"];

	destinationElement.dropPoint = point;
}


- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject *)dInstance
									entityMapping:(NSEntityMapping *)mapping
										  manager:(NSMigrationManager *)manager
											error:(NSError * _Nullable __autoreleasing *)error {
	
	NSError *errorCreate = NULL;
	BOOL result = [super createRelationshipsForDestinationInstance: dInstance
													 entityMapping: mapping
														   manager: manager
															 error: &errorCreate];

	NSString *keyDocumentElement = NSStringFromClass([RptqDocumentElement class]);
	if ([dInstance.entity.name hasPrefix:keyDocumentElement]) {
		NSArray *dInstances = [[NSArray alloc] initWithObjects:dInstance, nil];
		NSArray <__kindof NSManagedObject *> *sInstances = [manager sourceInstancesForEntityMappingNamed:mapping.name
																					destinationInstances:dInstances];
		NSAssert(dInstances.count == 1, @"We expect one and only one result.");
		NSManagedObject *element = sInstances[0];
		//NSString *key = NSStringFromClass([RptqBorder class]);
		NSManagedObjectContext *destinationContext = manager.destinationContext;
		NSAssert(destinationContext != nil, @"We need a managed object context.");
		__kindof RptqDocumentElement *dElement = (RptqDocumentElement *)dInstance;
		[self addBorderToElement:dElement fromElement:element forContext:destinationContext];
		[self addPaddingToElement:dElement fromElement:element forContext:destinationContext];
		[self addRectToElement:dElement fromElement:element forContext:destinationContext];
		[self addNumericFormatToElement:dElement fromElement:element forContext:destinationContext];
		[self addAlignmentToElement:dElement fromElement:element forContext:destinationContext];
		[self addTextStyleToElement:dElement fromElement:element forContext:destinationContext];
		[self addPointToElement:dElement fromElement:element forContext:destinationContext];
		
		//NSError *errorSave = NULL;
		//[destinationContext save:&errorSave];
	}
	return result;
}

- (BOOL)endRelationshipCreationForEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError * _Nullable __autoreleasing *)error {
	return [super endRelationshipCreationForEntityMapping:mapping manager:manager error:error];
}

- (NSValue *)migrateValueFromPointX:(NSNumber *)x pointY:(NSNumber *)y {
	return [NSValue valueWithCGPoint:CGPointMake(x.floatValue, y.floatValue)];
}

- (MADAlignment *)migrateValueFromAlignmentHorizontal:(NSNumber *)horizontal
											 vertical:(NSNumber *)vertical {
	int16_t h, v;
	CFNumberGetValue((__bridge CFNumberRef _Nonnull)horizontal, kCFNumberSInt16Type, &h);
	CFNumberGetValue((__bridge CFNumberRef _Nonnull)vertical, kCFNumberSInt16Type, &v);
	MADAlignment *a = [[MADAlignment alloc] initWithHorizontal:h vertical:v];
	return a;
}

- (UIColor *)migrateColorFromData:(NSData *)colorData {
	if (colorData == nil) return nil;
	NSError *error = nil;
	UIColor *color = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:colorData error:&error];
	if (error != nil) {
		os_log_error(GetDesignerLog(), "%s: %@", __PRETTY_FUNCTION__, error);
	}
	return color;
}

- (MADMargin *)migrateValueFromMarginLeft:(NSNumber *)left
									right:(NSNumber *)right
									  top:(NSNumber *)top
								   bottom:(NSNumber *)bottom {
	id result = [[MADMargin alloc] initWithLeft: left.doubleValue
										  right: right.doubleValue
											top: top.doubleValue
										 bottom: bottom.doubleValue];
	return result;
}

- (MADPadding *)migrateValueFromPaddingLeft:(NSNumber *)left
									  right:(NSNumber *)right
										top:(NSNumber *)top
									 bottom:(NSNumber *)bottom {
	id padding = [[MADPadding alloc] initWithLeft: left.doubleValue
											right: right.doubleValue
											  top: top.doubleValue
										   bottom: bottom.doubleValue];
	return padding;
}

- (MADTextStyle *)migrateTextStyleBold:(NSNumber *)bold
						 strikethrough:(NSNumber *)strikethrough
								italic:(NSNumber *)italic
							 underline:(NSNumber *)underline {
	id textStyle = [[MADTextStyle alloc] initWithBold: bold.boolValue
											   italic: italic.boolValue
											underline: underline.boolValue
										strikethrough: strikethrough.boolValue];
	return textStyle;
}

- (NSValue *)migrateValueFromSizeWidth:(NSNumber *)width height:(NSNumber *)height {
	CGSize s = CGSizeMake(width.floatValue, height.floatValue);
	return [NSValue valueWithCGSize:s];
}

- (MADBorderStyle *)migrateValueFromBorderHeightBottom:(NSNumber *)heightBottom
											 heightTop:(NSNumber *)heightTop
											 widthLeft:(NSNumber *)widthLeft
											widthRight:(NSNumber *)widthRight
										   styleBottom:(NSNumber *)styleBottom
											  styleTop:(NSNumber *)styleTop
											 styleLeft:(NSNumber *)styleLeft
											styleRight:(NSNumber *)styleRight {
	if (heightBottom == nil ||
		heightTop == nil ||
		widthLeft == nil ||
		widthRight == nil ||
		styleBottom == nil ||
		styleTop == nil ||
		styleRight == nil ||
		styleBottom == nil) return nil;
	
	int16_t ls, rs, ts, bs;

	CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleLeft, kCFNumberSInt16Type, &ls);
	CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleRight, kCFNumberSInt16Type, &rs);
	CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleTop, kCFNumberSInt16Type, &ts);
	CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleBottom, kCFNumberSInt16Type, &bs);

	id style = [[MADBorderStyle alloc] initWithLeft: widthLeft.floatValue
											  right: widthRight.floatValue
												top: heightTop.floatValue
											 bottom: heightBottom.floatValue
										  leftStyle: ls
										 rightStyle: rs
										   topStyle: ts
										bottomStyle: bs];
	
	return style;
}

- (MADCurrencyFormatter *)migrateCurrencyFormatterForCurrencyEnabled:(NSNumber *)enabled
															  locale:(NSString *)locale
														decimalCount:(NSNumber *)decimalCount {
	MADCurrencyFormatter *currency = [[MADCurrencyFormatter alloc] init];
	currency.enabled = [enabled boolValue];
	currency.decimalCount = [decimalCount integerValue];
	currency.locale = [NSLocale currentLocale];
	return currency;
}

- (NSString *)migrateValueFromMySQLDatabaseName:(NSString *)mySQLDBName
									  tdsDBName:(NSString *)tdsDBName {
	NSString *databaseName;
	if (mySQLDBName.length > 0)
		databaseName = mySQLDBName.copy;
	else if (tdsDBName.length > 0)
		databaseName = tdsDBName.copy;

	return databaseName;
}

- (NSString *)migrateStringNotNullOrEmpty:(NSString *)s1
								  string2:(NSString *)s2 {
	return s1.length > 0 ? s1 : s2;
}

- (NSNumber *)migrateValueInt64NotZero:(NSNumber *)v1
								value2:(NSNumber *)v2 {
	return [v1 isEqualToNumber: @0] ? v2 : v1;
	
}

@end
