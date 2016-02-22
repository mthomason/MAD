//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+DocumentInformation.H"

static NSString * const DocumentInfo            = @"MADStoryboardDocumentInformation";

@implementation UIStoryboard (DocumentInformation)

+ (instancetype)DocumentInfo {
    return [self storyboardWithName: DocumentInfo bundle:[NSBundle mainBundle]];
}

@end
