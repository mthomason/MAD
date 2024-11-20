//
//  NSAttributedString+QueryViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADAttributedStringQueryController_h
#define Reports_MADAttributedStringQueryController_h

#import <Foundation/NSAttributedString.h>

@interface MADAttributedStringQueryController : NSAttributedString

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

@interface MADStringQueryController : NSString

+ (instancetype)newStringFieldDisplayWithTable:(NSString *)table andField:(NSString *)field;

@end

#endif
