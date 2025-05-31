//
//  MADAttributedStringQueryController.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADAttributedStringQueryController.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADFoundation/MADStringUtilities.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSParagraphStyle.h>

@implementation MADAttributedStringQueryController

+ (NSAttributedString *)attributedStringForQueryPredicateWithLeftText:(NSString *)leftText
										   symbol:(NSString *)symbol
										rightText:(NSString *)rightText {
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	NSString *messageText = [[NSString alloc] initWithFormat:@"%1$@ %2$@ %3$@", leftText, symbol, rightText];
	
	NSDictionary *attributes = @{ NSFontAttributeName: font };
	UIColor *color = [MADColorEverydayApps newColorBlue];
	NSDictionary *attributesCaption = @{ NSForegroundColorAttributeName: color };
	
	NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
	NSRange rangeMiddle = [messageText rangeOfString:symbol];
	[message addAttributes:attributesCaption range:rangeMiddle];
	
	return message;
}

+ (NSAttributedString *)attributedStringForQuerySectionGroupWithField:(NSString *)field
															  andSort:(NSString *)sort {
	field = field ?: @"";
	sort = sort ?: @"";
	
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	UIFont *fontCaption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
	
	NSMutableParagraphStyle *paragraphStyleLeft = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyleLeft.alignment = NSTextAlignmentLeft;
	
	NSMutableParagraphStyle *paragraphStyleRight = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyleRight.alignment = NSTextAlignmentRight;
	
	NSString *messageText = [NSString stringWithFormat:@"%@ %@", field, sort];
	NSDictionary *attributes = @{ NSFontAttributeName: font };
	
	NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
	
	NSDictionary *attributesLeft = @{ NSParagraphStyleAttributeName: paragraphStyleLeft };
	UIColor *color = [MADColorEverydayApps newColorBlue];
	NSDictionary *attributesRight = @{
		NSParagraphStyleAttributeName: paragraphStyleLeft,
		NSFontAttributeName: fontCaption,
		NSForegroundColorAttributeName: color
	};
	
	[message addAttributes:attributesLeft range:[messageText rangeOfString:field]];
	[message addAttributes:attributesRight range:[messageText rangeOfString:sort]];
	
	return message;
}

+ (NSAttributedString *)attributedStringForQuerySectionLinksWithLeftString:(NSString *)leftString
															   rightString:(NSString *)rightString
														  linksDescription:(NSString *)linksDescription {

	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	UIFont *fontCaption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
	
	NSMutableParagraphStyle *paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraph.headIndent = 20.0;
	
	NSString *messageText = [NSString stringWithFormat:@"%@ %@ %@", leftString, linksDescription, rightString];
	
	NSDictionary *attributes = @{
		NSFontAttributeName: font,
		NSParagraphStyleAttributeName: paragraph
	};
	
	UIColor *color = [MADColorEverydayApps newColorBlue];
	NSDictionary *attributesAlt = @{
		NSFontAttributeName: fontCaption,
		NSForegroundColorAttributeName: color
	};
	
	NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
	NSRange rangeLinkDesc = [messageText rangeOfString:linksDescription];
	[message addAttributes:attributesAlt range:rangeLinkDesc];
	
	return message;
}

+ (NSAttributedString *)attributedStringForQuerySectionDatasourceWithMessage:(NSString *)localizedMessage
													   databaseType:(NSString *)databaseType
														 schemaName:(NSString *)schemaName {
	
	NSString *text = [NSString stringWithFormat:localizedMessage, databaseType, schemaName];
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	NSDictionary *attributes = @{ NSFontAttributeName: font };
	
	UIFont *fontItalic = [UIFont italicSystemFontOfSize:font.pointSize];
	NSDictionary *attributeItalic = @{ NSFontAttributeName: fontItalic };
	
	NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
	
	NSRange rangeDB = [text rangeOfString:databaseType];
	[message removeAttribute:NSFontAttributeName range:rangeDB];
	[message addAttributes:attributeItalic range:rangeDB];
	
	NSRange rangeSchema = [text rangeOfString:schemaName];
	[message removeAttribute:NSFontAttributeName range:rangeSchema];
	[message addAttributes:attributeItalic range:rangeSchema];
	
	return message;
}

@end

@implementation MADStringQueryController

+ (NSString *)stringForFieldDisplayWithTable:(NSString *)table andField:(NSString *)field {
	NSString *result = [MADStringUtilities stringByAppendingPeriod:table.capitalizedString];
	return [result stringByAppendingString:field.capitalizedString];
}

@end
