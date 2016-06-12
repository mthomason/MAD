//
//  NSAttributedString+QueryViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (QueryViewController)

+ (instancetype)newAttributedStringQueryPredicate:(NSString *)leftText
                                           symbol:(NSString *)symbol
                                        rightText:(NSString *)rightText;
+ (instancetype)newAttributedStringQuerySectionGroupWithField:(NSString *)field
                                                      andSort:(NSString *)sort;

+ (instancetype)newAttributedStringQuerySectionLinks:(NSString *)leftString
                                         rightString:(NSString *)rightString
                                    linksDescription:(NSString *)linksDescription;

+ (instancetype)newAttributedStringQuerySectionDatasourceForMessage:(NSString *)localizedMessage
                                                       databaseType:(NSString *)databaseType
                                                         schemaName:(NSString *)schemaName;

@end

@interface NSString (QueryField)

+ (instancetype)newStringFieldDisplayWithTable:(NSString *)table andField:(NSString *)field;

@end
