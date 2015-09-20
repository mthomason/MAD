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
static NSString * const About                   = @"MADStoryboardAbout";
static NSString * const QueryVisualization      = @"MADQueryVisualization";
@implementation UIStoryboard (Designer)

+ (instancetype)Designer {
    return [UIStoryboard storyboardWithName: Designer bundle:nil];
}

+ (instancetype)Licensing {
    return [self storyboardWithName: Licensing bundle:nil];
}

+ (instancetype)About {
    return [self storyboardWithName: About bundle:nil];
}

+ (instancetype)InformationTable {
    return [self storyboardWithName: InformationTable bundle:[NSBundle mainBundle]];
}

+ (instancetype)DocumentInfo {
    return [self storyboardWithName: DocumentInfo bundle:[NSBundle mainBundle]];
}

+ (instancetype)NewDocument {
    return [self storyboardWithName: NewDocument bundle:[NSBundle mainBundle]];
}

+ (instancetype)Toolbox {
    return [self storyboardWithName: Toolbox bundle: [NSBundle mainBundle]];
}

+ (instancetype)ObjectSelector {
    return [self storyboardWithName: ObjectSelector bundle: [NSBundle mainBundle]];
}

+ (instancetype)QueryVisualization {
    return [self storyboardWithName: QueryVisualization bundle: [NSBundle mainBundle]];
}

@end
