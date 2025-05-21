//
//  NSAttributedString+QueryViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "NSAttributedString+QueryViewController.h"
#import <UIKit/UIFont.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSParagraphStyle.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADFoundation/MADStringUtilities.h>

@implementation MADAttributedStringQueryController

+ (instancetype)newAttributedStringQueryPredicate:(NSString *)leftText
										   symbol:(NSString *)symbol
										rightText:(NSString *)rightText {
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	NSString *formatString = @"%1$@ %2$@ %3$@";
	NSString *messageText = [[NSString alloc] initWithFormat:formatString,
															 leftText, symbol, rightText];
	
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
												font, NSFontAttributeName, nil];
	UIColor *color = [MADColorEverydayApps newColorBlue];
	NSDictionary *attributesCaption = [[NSDictionary alloc] initWithObjectsAndKeys:
									   color, NSForegroundColorAttributeName, nil];
	
	id message;
	message = [[NSMutableAttributedString alloc] initWithString: messageText
													 attributes: attributes];
	NSRange rangeMiddle = [messageText rangeOfString:symbol];
	[message addAttributes: attributesCaption
					 range: rangeMiddle];

	return message;
}

+ (instancetype)newAttributedStringQuerySectionGroupWithField:(NSString *)field
													  andSort:(NSString *)sort {
	if (field == nil) {
		field = @"";
	}
	if (sort == nil) {
		sort = @"";
	}
	id message;
	UIFont *font =          [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	UIFont *fontCaption =   [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
	
	NSMutableParagraphStyle *paragraphStyleLeft, *paragraphStyleRight;
	paragraphStyleLeft = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyleRight = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyleLeft.alignment = NSTextAlignmentLeft;
	paragraphStyleRight.alignment = NSTextAlignmentRight;
	
	NSString *formatString = @"%1$@ %2$@";
	
	NSString *messageText = [[NSString alloc] initWithFormat: formatString,
							 field, sort];
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								font, NSFontAttributeName, nil];
	message = [[NSMutableAttributedString alloc] initWithString: messageText
													 attributes: attributes];
	NSDictionary *attributesLeft, *attributesRight;
	attributesLeft = [[NSDictionary alloc] initWithObjectsAndKeys:
					  paragraphStyleLeft, NSParagraphStyleAttributeName, nil];
	UIColor *color = [MADColorEverydayApps newColorBlue];
	attributesRight = [[NSDictionary alloc] initWithObjectsAndKeys:
					   paragraphStyleLeft, NSParagraphStyleAttributeName,
					   fontCaption,        NSFontAttributeName,
					   color,              NSForegroundColorAttributeName, nil];
	NSRange rangeLeft = [messageText rangeOfString:field];
	NSRange rangeRange = [messageText rangeOfString:sort];
	[message addAttributes:attributesLeft range:rangeLeft];
	[message addAttributes:attributesRight range:rangeRange];
	
	return message;
}

+ (instancetype)newAttributedStringQuerySectionLinks:(NSString *)leftString
										 rightString:(NSString *)rightString
									linksDescription:(NSString *)linksDescription {
	
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	UIFont *fontCaption = [UIFont preferredFontForTextStyle: UIFontTextStyleCaption1];
	NSString *messageText = @"%@ %@ %@";

	NSMutableParagraphStyle *paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraph.headIndent = 20.0;
	
	messageText = [[NSString alloc] initWithFormat:messageText,
												   leftString,
												   linksDescription,
												   rightString];
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
									font,           NSFontAttributeName,
									paragraph, NSParagraphStyleAttributeName, nil];
	UIColor *color = [MADColorEverydayApps newColorBlue];
	NSDictionary *attributesAlt = [[NSDictionary alloc] initWithObjectsAndKeys:
											fontCaption, NSFontAttributeName,
											color,       NSForegroundColorAttributeName, nil];
	
	NSRange rangeLinkDesc = [messageText rangeOfString:linksDescription];
	id message;
	message = [[NSMutableAttributedString alloc] initWithString: messageText
													 attributes: attributes];
	[message addAttributes:attributesAlt range:rangeLinkDesc];
	return message;
}

+ (instancetype)newAttributedStringQuerySectionDatasourceForMessage:(NSString *)localizedMessage
													   databaseType:(NSString *)databaseType
														 schemaName:(NSString *)schemaName {
	
	NSString *text = [[NSString alloc] initWithFormat: localizedMessage,
													   databaseType, schemaName];
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								font, NSFontAttributeName, nil];
	
	UIFont *fontItalic = [UIFont italicSystemFontOfSize:font.pointSize];
	NSDictionary *attributeStroke = [[NSDictionary alloc] initWithObjectsAndKeys:
									 fontItalic, NSFontAttributeName, nil];
	
	id message;
	message = [[NSMutableAttributedString alloc] initWithString: text
													 attributes: attributes];
	NSRange range = [[message string] rangeOfString:databaseType];
	[message removeAttribute: NSFontAttributeName range: range];
	[message addAttributes: attributeStroke range: range];
	
	range = [[message string] rangeOfString:schemaName];
	[message removeAttribute: NSFontAttributeName range: range];
	[message addAttributes: attributeStroke range: range];
	return message;
}

@end

@implementation MADStringQueryController

+ (instancetype)newStringFieldDisplayWithTable:(NSString *)table andField:(NSString *)field {
	id result = [MADStringUtilities stringByAppendingPeriod:table.capitalizedString];
	result = [result stringByAppendingString:field.capitalizedString];
	return result;
}

@end
