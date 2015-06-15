//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+Designer.h"

static NSString * const Designer                = @"MADDesigner";
static NSString * const Licensing               = @"MADLicensing";
static NSString * const Toolbox                 = @"MADToolbox";
static NSString * const ObjectSelector          = @"MADStoryboardObjectSelector";
static NSString * const NewDocument             = @"MADStoryboardNewDocument";
static NSString * const DocumentInfo            = @"MADStoryboardDocumentInformation";
static NSString * const InformationTable        = @"MADStoryboardInformationTable";
static NSString * const About                   = @"MADStoryboardAboutTable";

@implementation UIStoryboard (Designer)

+ (instancetype)About {
    return [UIStoryboard storyboardWithName: About bundle:[NSBundle mainBundle]];
}

+ (instancetype)InformationTable {
    return [UIStoryboard storyboardWithName: InformationTable bundle:[NSBundle mainBundle]];
}

+ (instancetype)DocumentInfo {
    return [UIStoryboard storyboardWithName: DocumentInfo bundle:[NSBundle mainBundle]];
}

+ (instancetype)NewDocument {
    return [UIStoryboard storyboardWithName: NewDocument bundle:[NSBundle mainBundle]];
}

+ (instancetype)designer {
    return [UIStoryboard storyboardWithName: Designer bundle:nil];
}

+ (instancetype)licensing {
    return [UIStoryboard storyboardWithName: Licensing bundle:nil];
}

+ (instancetype)toolbox {
    return [UIStoryboard storyboardWithName: Toolbox bundle: [NSBundle mainBundle]];
}

+ (instancetype)objectSelector {
    return [UIStoryboard storyboardWithName: ObjectSelector bundle: [NSBundle mainBundle]];
}

@end
