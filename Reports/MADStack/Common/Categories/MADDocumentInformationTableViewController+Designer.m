//
//  MADDocumentInformationTableViewController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentInformationTableViewController+Designer.h"
#import "UIStoryboard+Designer.h"

static NSString * const DocInfo = @"MADIdentifierDocumentInformationTableViewController";

@implementation MADDocumentInformationTableViewController (Designer)

+ (instancetype)DocumentInformation {
    UIStoryboard *sb = [UIStoryboard DocumentInfo];
    return [sb instantiateViewControllerWithIdentifier: DocInfo];
}

@end
