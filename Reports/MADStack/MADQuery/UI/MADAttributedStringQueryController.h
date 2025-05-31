//
//  MADAttributedStringQueryController.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADAttributedStringQueryController_h
#define Reports_MADAttributedStringQueryController_h

#import <Foundation/NSObject.h>

@class NSString, NSAttributedString;

@interface MADAttributedStringQueryController : NSObject

+ (NSAttributedString *)attributedStringForQueryPredicateWithLeftText:(NSString *)leftText
															   symbol:(NSString *)symbol
															rightText:(NSString *)rightText;
+ (NSAttributedString *)attributedStringForQuerySectionGroupWithField:(NSString *)field
															  andSort:(NSString *)sort;

+ (NSAttributedString *)attributedStringForQuerySectionLinksWithLeftString:(NSString *)leftString
															   rightString:(NSString *)rightString
														  linksDescription:(NSString *)linksDescription;

+ (NSAttributedString *)attributedStringForQuerySectionDatasourceWithMessage:(NSString *)localizedMessage
																databaseType:(NSString *)databaseType
																  schemaName:(NSString *)schemaName;

@end

@interface MADStringQueryController : NSObject

+ (NSString *)stringForFieldDisplayWithTable:(NSString *)table andField:(NSString *)field;

@end

#endif
