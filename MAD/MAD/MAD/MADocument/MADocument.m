//
//  MADocument.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADocument.h"

#import <setjmp.h>
#import <asl.h>

#import <Foundation/NSEnumerator.h>

#import <CoreData/NSManagedObjectModel.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSPersistentStoreCoordinator.h>
#import <CoreData/CoreDataErrors.h>
#import <CoreData/NSManagedObjectID.h>

#import <UIKit/UIScreen.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIPrintPaper.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIPrintInteractionController.h>

#import <MADFoundation/UIScreen+Properties.h>
#import <MADFoundation/MADURL.h>
#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/NSString+Common.h>
#import <MADFoundation/MADErrorUserInfo.h>
#import <MADFoundation/MADCredential.h>

#import <MADFileManager/MADFileUtilities.h>

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADThread.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADDocumentProtocol.h"
#import "MADDatabaseProtocol.h"

#import "MADSortOrder.h"
#import "MADConstants.h"


#import "MADDataTable.h"

#import "MTQuery.h"
#import "MTQueryFull.h"

#import "MADConstants.h"

#import "MADActivityIndicator.h"
#import "MADocumentState.h"

#import "MADReportFormatter.h"
#import "MADDatabaseConnection.h"

#import "MADNotificationDidFormatPage.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqBorder.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqAlignment.h"

#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSectionRows+Extras.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

#import "RptqDatabaseCredentals.h"
#import "RptqDatabaseCredentals+Extras.h"

#import "RptqDocumentElementLabelDataField.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqTextStyle.h"
#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentElementAggregate.h"

#import "RptqDocumentSectionRows.h"

#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"

#import "RptqDocumentSectionEnumerator.h"
#import "RptqRect.h"
#import "RptqSize.h"
#import "MADSectionLayoutManager.h"
#import "RptqDirectionalAsymmetry.h"

#import "MADDataTableFast.h"
#import "MTDatabase.h"

#import "MADModel.h"
#import "MADModelDocument.h"
#import "MADModelDatabase.h"

#import "MADPrintPageRenderer.h"

#import "NSString+RelativePath.h"

#import "MADImageThumbnail.h"

#import "miniz.h"

#import "MADArchiveManager.h"

#import <mach/machine/vm_param.h>

#import "MADNotificationFileUpdate.h"

#import "NSPredicate+Creators.h"

typedef void (^MTCompletionHandlerSuccess)(BOOL success);

/*
 {
    additionalContent =     {
        generator = "MAD Designer";
        "thumbnail.png" = "<UIImage: 0x1fea0b10>";
        version = 1;
    };
    fileType = "com.everydayapps.productivity.mad";
    parentContext = "<NSManagedObjectContext: 0xffffffff>";
 }
 */

NSString * const MADMimeType                                    = @"application/vnd.everydayapps.mad";
NSString * const MADDocumentInfoKeyThumbnail                    = @"thumbnail";

static NSString * const MTDocumentAdditionalContentKey          = @"additionalContent";
static NSString * const MTDocumentFileTypeKey                   = @"fileType";
static NSString * const MTDocumentParentContextKey              = @"parentContext";

static NSString * const MADDocumentInfoKeyThumbnailStandard     = @"thumbnail.png";
static NSString * const MADDocumentInfoKeyThumbnailRetna        = @"thumbnail@2x.png";
static NSString * const MADDocumentInfoKeyMeta                  = @"meta.plist";
static NSString * const MADDocumentInfoKeyVersion               = @"version";
static NSString * const MADDocumentInfoKeyGenerator             = @"generator";

static NSString * const MADFileNameMetaPlist                   = @"meta.plist";

static NSString * const MADPersistentStoreAliasMad             = @"analyitics";
static NSString * const MADDocumentTypeUtiMad                  = @"com.everydayapps.productivity.mad";

static NSString * const MNSInterfaceMessageErrorFailedToCreateReport    = @"Failed to create report document.";
static NSString * const MNSInterfaceTitleProblem                        = @"Problem";

static NSString * const MADManagedObjectModelName                       = @"MAD";
static NSString * const MADManagedObjectModelExtention                  = @"momd";

#if MAD_DESIGNER == 1 || MAD_TEST == 1
  NSString * const MADUbiquitousPeerToken = @"MADDESIGNER";
#elif MAD_VIEWER == 1
  NSString * const MADUbiquitousPeerToken = "MADVIEWER";
#endif

void fail(char *err, const char*err2, int n);
void fail(char *err, const char*err2, int n) { }
void msg(const char *err);
void msg(const char *err) { }
void madwarn(char *err,  const char*err2);
void madwarn(char *err,  const char*err2) { }

@interface MADocument ()
    <MADReportFormatterDataSource,
        MADCacheProtocol,
        MADDatabaseProtocol>

    @property (nonatomic, readwrite, strong) RptqDocument *activeDocumentModel;
    @property (nonatomic, readwrite, strong) NSManagedObjectModel *madManagedObjectModel;
    @property (nonatomic, readwrite, strong) NSDictionary *madPersistentStoreOptions;

    @property (nonatomic, readwrite, strong) NSMutableDictionary *extraInformation;
    @property (nonatomic, readwrite, strong) UIImage *thumbnail;

    @property (nonatomic, readwrite, strong) MADDataTableFast *dataTable;
    @property (nonatomic, readwrite, strong) MTDatabase *database;
    @property (nonatomic, readwrite, strong) MTQueryFull *mainQuery;

    @property (nonatomic, readwrite, strong) NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *sectionLayoutManagers;

    @property (nonatomic, readwrite, strong) MADModelDocument *documentModel;
    @property (nonatomic, readwrite, strong) MTPaper *paper;

    @property (nonatomic, readwrite, copy) NSURL *urlDataTableCache;
    @property (nonatomic, readwrite, copy) NSURL *urlGuts;
    @property (nonatomic, readwrite, copy) NSURL *urlMetaPlaylist;

@end

@implementation MADocument {
    BOOL _didRefresh;
}

@synthesize sectionLayoutManagers = _sectionLayoutManagers;

#pragma mark -
#pragma mark MADPrintPageRendererDataSourceProtocol

@dynamic filename;

@synthesize database = _database;
@synthesize dataTable = _dataTable;
@synthesize reportFormatter = _reportFormatter;

#pragma mark -
#pragma mark Adjust

- (void)updateElements:(NSSet <NSNumber *> *)identifiers
            actionName:(NSString *)actionName
         updateHandler:(void (^)(long long identifier))updateHandler
           undoHandler:(void (^)(id target))undoHandler {
    //NSString *actionName = NSLocalizedString(underline ? @"Font Size" : @"Font Size",
    //                                         underline ? @"Font Size" : @"Font Size");
    NSNumber *identifier;
    //RptqDocumentElement *element;
    //double previousFontsize = 0.0;
    for (identifier in identifiers) {
        updateHandler(identifier.longLongValue);
        //element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
        //                                              fromObjectContext:self.managedObjectContext];
        //previousFontsize = element.fontsize;
        //element.fontsize = fontsize;
    }
    //void (^undoHandler)(id target);
    //NSSet <NSNumber *> *elementIDs = identifiers.copy;
    //undoHandler = ^(id  _Nonnull target) {
    //    [(MADocument *)target updateElements:elementIDs setFontsize:previousFontsize];
    //};
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBold:(BOOL)bold {
    NSString *actionName = NSLocalizedString(bold ? @"Bold" : @"Disable Bold",
                                             bold ? @"Bold" : @"Disable Bold");
    NSNumber *identifier;
    RptqDocumentElement *element;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        element.textStyle.bold = bold;
    }
    
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    if (bold) {
        undoHandler = ^(id  _Nonnull target) {
            [(MADocument *)target updateElements:elementIDs setBold:NO];
        };
    } else {
        undoHandler = ^(id  _Nonnull target) {
            [(MADocument *)target updateElements:elementIDs setBold:YES];
        };
    }
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setItalic:(BOOL)italic {
    NSString *actionName = NSLocalizedString(italic ? @"Italic" : @"Disable Italic",
                                             italic ? @"Italic" : @"Disable Italic");
    NSNumber *identifier;
    RptqDocumentElement *element;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        element.textStyle.italic = italic;
    }
    
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    if (italic) {
        undoHandler = ^(id  _Nonnull target) {
            [(MADocument *)target updateElements:elementIDs setItalic:NO];
        };
    } else {
        undoHandler = ^(id  _Nonnull target) {
            [(MADocument *)target updateElements:elementIDs setItalic:YES];
        };
    }
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setStrikethrough:(BOOL)strikethrough {
    NSString *actionName = NSLocalizedString(strikethrough ? @"Strikethrough" : @"Disable Strikethrough",
                                             strikethrough ? @"Strikethrough" : @"Disable Strikethrough");
    NSNumber *identifier;
    RptqDocumentElement *element;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        element.textStyle.strikethrough = strikethrough;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    if (strikethrough) {
        undoHandler = ^(id  _Nonnull target) {
            [(MADocument *)target updateElements:elementIDs setStrikethrough:NO];
        };
    } else {
        undoHandler = ^(id  _Nonnull target) {
            [(MADocument *)target updateElements:elementIDs setStrikethrough:YES];
        };
    }
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setUnderline:(BOOL)underline {
    NSString *actionName = NSLocalizedString(underline ? @"Underline" : @"Disable Underline",
                                             underline ? @"Underline" : @"Disable Underline");
    NSNumber *identifier;
    RptqDocumentElement *element;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        element.textStyle.underline = underline;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    if (underline) {
        undoHandler = ^(id  _Nonnull target) {
            [(MADocument *)target updateElements:elementIDs setUnderline:NO];
        };
    } else {
        undoHandler = ^(id  _Nonnull target) {
            [(MADocument *)target updateElements:elementIDs setUnderline:YES];
        };
    }
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setFontsize:(double)fontsize {
    NSString *actionName = NSLocalizedString(underline ? @"Font Size" : @"Font Size",
                                             underline ? @"Font Size" : @"Font Size");
    NSNumber *identifier;
    RptqDocumentElement *element;
    double previousFontsize = 0.0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previousFontsize = element.fontsize;
        element.fontsize = fontsize;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setFontsize:previousFontsize];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setFontname:(NSString *)fontname {
    NSString *actionName = NSLocalizedString(@"Font Name %@",
                                             @"Font Name %@");
    actionName = [[NSString alloc] initWithFormat:actionName, fontname];
    NSNumber *identifier;
    RptqDocumentElement *element;
    NSString *previousFontname = nil;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        if (previousFontname == nil) previousFontname = element.fontname.copy;
        element.fontname = fontname.copy;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setFontname:previousFontname];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setVerticalAlignment:(int16_t)verticalAlignment {
    NSString *actionName = NSLocalizedString(@"Vertical Alignment",
                                             @"Vertical Alignment");
    NSNumber *identifier;
    RptqDocumentElement *element;
    int16_t previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.alignment.vertical;
        element.alignment.vertical = verticalAlignment;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setVerticalAlignment:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setHorizontalAlignment:(int16_t)horizontalAlignment {
    NSString *actionName = NSLocalizedString(@"Horizontal Alignment",
                                             @"Horizontal Alignment");
    NSNumber *identifier;
    RptqDocumentElement *element;
    int16_t previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.alignment.horizontal;
        element.alignment.horizontal = horizontalAlignment;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setHorizontalAlignment:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setSizeWidth:(float)width {
    NSString *actionName = NSLocalizedString(@"Size Width",
                                             @"Size Width");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.rect.size.width;
        element.rect.size.width = width;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setSizeWidth:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setSizeHeight:(float)height {
    NSString *actionName = NSLocalizedString(@"Size Height",
                                             @"Size Height");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.rect.size.height;
        element.rect.size.height = height;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setSizeHeight:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginBottom:(float)bottom {
    NSString *actionName = NSLocalizedString(@"Margin Bottom",
                                             @"Margin Bottom");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.margin.bottom;
        element.margin.bottom = bottom;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setMarginBottom:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginTop:(float)top {
    NSString *actionName = NSLocalizedString(@"Margin Top",
                                             @"Margin Top");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.margin.top;
        element.margin.top = top;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setMarginTop:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginLeft:(float)left {
    NSString *actionName = NSLocalizedString(@"Margin Left",
                                             @"Margin Left");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.margin.left;
        element.margin.left = left;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setMarginLeft:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginRight:(float)right {
    NSString *actionName = NSLocalizedString(@"Margin Right",
                                             @"Margin Right");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.margin.right;
        element.margin.right = right;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setMarginRight:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingBottom:(float)bottom {
    NSString *actionName = NSLocalizedString(@"Padding Bottom",
                                             @"Padding Bottom");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.padding.bottom;
        element.padding.bottom = bottom;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setPaddingBottom:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingTop:(float)top {
    NSString *actionName = NSLocalizedString(@"Padding Top",
                                             @"Padding Top");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.padding.top;
        element.padding.top = top;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setPaddingTop:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingLeft:(float)left {
    NSString *actionName = NSLocalizedString(@"Padding Left",
                                             @"Padding Left");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.padding.left;
        element.padding.left = left;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setPaddingLeft:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingRight:(float)right {
    NSString *actionName = NSLocalizedString(@"Padding Right",
                                             @"Padding Right");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.padding.right;
        element.padding.right = right;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setPaddingRight:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderBottom:(float)bottom {
    NSString *actionName = NSLocalizedString(@"Border Bottom",
                                             @"Border Bottom");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.border.width.bottom;
        element.border.width.bottom = bottom;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setBorderBottom:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderTop:(float)top {
    NSString *actionName = NSLocalizedString(@"Border Top",
                                             @"Border Top");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.border.width.top;
        element.border.width.top = top;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setBorderTop:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderLeft:(float)left {
    NSString *actionName = NSLocalizedString(@"Border Left",
                                             @"Border Left");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.border.width.left;
        element.border.width.left = left;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setBorderLeft:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderRight:(float)right {
    NSString *actionName = NSLocalizedString(@"Border Right",
                                             @"Border Right");
    NSNumber *identifier;
    RptqDocumentElement *element;
    float previous = 0;
    for (identifier in identifiers) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:self.managedObjectContext];
        previous = element.border.width.right;
        element.border.width.right = right;
    }
    void (^undoHandler)(id target);
    NSSet <NSNumber *> *elementIDs = identifiers.copy;
    undoHandler = ^(id  _Nonnull target) {
        [(MADocument *)target updateElements:elementIDs setBorderRight:previous];
    };
    [self.undoManager setActionName:actionName];
    [self.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (NSArray *)groupLevelKeys:(NSUInteger)rowID {
        NSArray *groupLevelKeys;

    if (self.reportFormatter.numberOfGroups > 0) {
        
        NSDictionary *row = [self.dataTable copyDataForCacheId: rowID];
        groupLevelKeys = [self.reportFormatter newObjectArrayKeyValuesForResultRow: row];
        return groupLevelKeys;
        
    } else {
        
        groupLevelKeys = [[NSArray alloc] init];
        return groupLevelKeys;
        
    }
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    _thumbnail = nil;
    _madManagedObjectModel = nil;
}

- (void)resetCache {

    NSNumber *typeKey = [[NSNumber alloc] initWithShort: MADDataTableParametersType];
    NSNumber *type = [[NSNumber alloc] initWithShort: MADDataTableTypePhysical];
    NSNumber *objectIdKey = [[NSNumber alloc] initWithShort: MADDataTableParametersIdentifier];
    NSNumber *objectIdV = [[NSNumber alloc] initWithUnsignedInteger: self.filename.hash];
    NSDictionary *parameters;
    parameters = [[NSDictionary alloc] initWithObjectsAndKeys:type, typeKey, objectIdV, objectIdKey, nil];
    
    MADDataTableFast *datatable = [MADDataTableFast newDataTableWithDefinition:parameters];
    datatable.cacheDelegate = self;
    [datatable loadFromCacheWithUrl:self.urlDataTableCache];
    self.dataTable = datatable;

}

- (void)updateDatabaseWithConnection:(MADDatabaseConnection *)databaseConnection {
    MTDatabase *database;
    database = [MTDatabase newDatabaseWithConnection:databaseConnection];
    self.database = database;
}

- (void)removeObservers {
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextObjectsDidChangeNotification
                                                  object: self.managedObjectContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextDidSaveNotification
                                                  object: self.managedObjectContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextWillSaveNotification
                                                  object: self];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIDocumentStateChangedNotification
                                                  object: self];
    
}

#pragma mark -
#pragma mark Initalization

+ (instancetype)newManagedDocumentForURL:(NSURL *)url {
    id document = [[self alloc] initWithFileURL:url];
    return document;
}

- (instancetype)initWithFileURL:(NSURL *)url {
    return [self initWithFileURL:url andDatabaseConnection:nil];
}

- (instancetype)initWithFileURL:(NSURL *)url andDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
    if (self = [super initWithFileURL:url]) {
        
        _urlGuts = [MADURL newURLDocumentArchiveForFileURL: url
                                                 extension: MADFileExtentionMobleApplicationDocumentArchive];
        _urlMetaPlaylist = [_urlGuts URLByAppendingPathComponent: MADFileNameMetaPlist];
        
        //Initialize the main data table.
        NSString *filename = self.filename;

        MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:filename.hash];
        datatable.cacheDelegate = self;
        
        NSString *cacheName = [datatable newFilenameMDCache];
        NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
        self.urlDataTableCache = cacheUrl;
        [datatable loadFromCacheWithUrl:cacheUrl];
        self.dataTable = datatable;
        
        //Initzlize the main document state
        id documentState = [[MADocumentState alloc] init];
        self.documentStatus = documentState;
        
        //Initzlize the extra info output container
        id extraInfo = [[NSMutableDictionary alloc] initWithCapacity: 3];
        self.extraInformation = extraInfo;
        
        if (databaseConnection != nil) {
            MTDatabase *database = [MTDatabase newDatabaseWithConnection: databaseConnection];
            self.database = database;
        }
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver: self
                          selector: @selector(handleManagedObjectContextDidChange:)
                              name: NSManagedObjectContextObjectsDidChangeNotification
                            object: self.managedObjectContext];
        
        [defaultCenter addObserver: self
                          selector: @selector(handleManagedObjectContextDidSave:)
                              name: NSManagedObjectContextDidSaveNotification
                            object: self.managedObjectContext];
        
        [defaultCenter addObserver: self
                          selector: @selector(handleManagedObjectContextWillSave:)
                              name: NSManagedObjectContextWillSaveNotification
                            object: self];
        
        [defaultCenter addObserver: self
                          selector: @selector(handleDocumentStateChanged:)
                              name: UIDocumentStateChangedNotification
                            object: self];
        
        _didRefresh = NO;
    }
    return self;
}

#pragma mark -
#pragma mark Static Helpers

+ (void)close:(MADocument *)document
   completion:(void (^)(BOOL success, NSURL *fileURL, NSURL *cleanupURL))completion  {
    
    MADocument *strongDocument = document;
    
    [strongDocument removeObservers];
    
    NSURL *fileURL = strongDocument.fileURL.copy;
    NSURL *gutsUrl = strongDocument.urlGuts.copy;
    

    //UIImage *thumbnail = [MADImageThumbnail newImageThumbnailWithDocument:strongDocument];
    //strongDocument.thumbnail = thumbnail;
    //thumbnail = nil;
    
    if (strongDocument != nil) {
        //strongDocument.thumbnail = nil;
        if (![NSThread isMainThread]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [strongDocument closeWithCompletionHandler:^(BOOL successClose) {
                    completion(successClose, fileURL, gutsUrl);
                }];
            }];
        } else {
            [strongDocument closeWithCompletionHandler:^(BOOL successClose) {
                completion(successClose, fileURL, gutsUrl);
            }];
        }
    }

    
    //void (^closeCompletionHandler)(BOOL);
    //void (^origionalCompletionHandler)(BOOL, NSURL *);
    //origionalCompletionHandler = completion;
    
    //closeCompletionHandler = ^(BOOL successClose) {
    //    completion(successClose, fileURL, gutsUrl);
    //};
    
    //MADocument * __weak weakdoc = document;
    /*void (^ saveCompletionHandler)(BOOL);
     saveCompletionHandler = ^(BOOL success) {
     
     if (strongDocument != nil) {
     if (success) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
     [strongDocument closeWithCompletionHandler:^(BOOL successClose) {
     completion(successClose, fileURL, gutsUrl);
     }];
     }];
     }
     strongDocument.thumbnail = nil;
     }
     
     };*/
    //[[NSOperationQueue mainQueue] addOperationWithBlock:^{
    
    //UIImage *thumbnail = [MADImageThumbnail newImageThumbnailWithDocument:strongDocument];
    //strongDocument.thumbnail = thumbnail;
    //[strongDocument saveToURL: fileURL
    //         forSaveOperation: UIDocumentSaveForOverwriting
    //        completionHandler: ^(BOOL success) {
    
    //if (strongDocument != nil) {
    //    strongDocument.thumbnail = nil;
    //    //if (success) {
    //    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    //        [strongDocument closeWithCompletionHandler:^(BOOL successClose) {
    //            completion(successClose, fileURL, gutsUrl);
    //        }];
    //    }];
        //}
    //}
    
    //      }];
    //}];
    
    
}

// Helpers

- (MADModelDocument *)documentModel {
    if (!_documentModel) {
        MADModelDocument *documentModel;
        documentModel = [[MADModelDocument alloc] initWithContext:self.managedObjectContext];
        _documentModel = documentModel;
    }
    return _documentModel;
}

- (NSURL *)thumbnailURL {
    NSString *name = self.fileURL.lastPathComponent.stringByDeletingPathExtension;
    NSURL *url = [MADURL newURLThumbnailForHandle: name
                                 andRetinaDisplay: [UIScreen mainScreen].isRetnaDisplay];
    return url;
}

- (NSURL *)urlDataTableCache {
    NSString *cacheName = [self.dataTable newFilenameMDCache];
    return [self newUrlCacheForFilename:cacheName];
}

- (NSURL *)newUrlCacheForFilename:(NSString *)filename {
    NSURL *cacheUrl = [self.cachedFilesDirectory URLByAppendingPathComponent: filename
                                                                 isDirectory: NO];
    return cacheUrl;
}

#pragma mark -
#pragma mark MADCacheProtocol

- (NSURL *)cachedFilesDirectory {
    NSString *filename = self.filename;
    NSURL *result = [MADURL newURLCacheFilesDirectoryForFilename:filename];
    return result;
}

#pragma mark -
#pragma mark UIDocument

- (NSDictionary <NSNumber *, NSNumber *> *)layoutHeightsBySectionKey {
    NSMutableDictionary *dictionary;
    dictionary = [[NSMutableDictionary alloc] initWithCapacity:self.sectionLayoutManagers.count];

    [self.sectionLayoutManagers enumerateKeysAndObjectsUsingBlock:^(NSNumber *key,
                                                                    MADSectionLayoutManager *sectionLayoutManager,
                                                                    BOOL *stop) {
        
        NSNumber *height = [[NSNumber alloc] initWithDouble:sectionLayoutManager.size.height];
        dictionary[key] = height;
        
    }];
    return dictionary;
}

- (NSDictionary *)persistentStoreOptions {
    if (_madPersistentStoreOptions == nil) {
        NSDictionary *persistentStoreOptions;
        persistentStoreOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @YES, NSInferMappingModelAutomaticallyOption,
                                      @YES, NSMigratePersistentStoresAutomaticallyOption, nil];
        _madPersistentStoreOptions = persistentStoreOptions;
    }
    return _madPersistentStoreOptions;
}

#pragma mark -
#pragma mark Reading

/// Reading MADocument has the following steps:
/// 1. Unarchive the MAD file; it's a zip file (tar.bz2 maybe).
/// 2. Read the unarchived file.  It's currently a Core Data file.

- (BOOL)readFromURL:(NSURL *)url error:(NSError * __autoreleasing *)outError {

    __block BOOL success = NO;

    /// 1. Unarchive the MAD file; it's a zip file (tar.bz2 maybe).
    if ([url.pathExtension isEqualToString:MADFileExtentionMobleApplicationDocument]) {
        MADArchiveManager *archiveManager;
        archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: _urlGuts
                                                                archiveURL: url];
        if (!(success = [archiveManager unarchive])) {
            asl_log(NULL, NULL, ASL_LEVEL_ERR, "Document unarchive failed.");
        }
    }
    
    /// 2. Read the unarchived file.  It's currently a Core Data file.
    NSError *error = NULL;
    success = success ? [super readFromURL:_urlGuts error:&error] : NO;
    if (error) *outError = error;
    return success;
    
}

#pragma mark -
#pragma mark Error handling

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    [super handleError:error userInteractionPermitted:userInteractionPermitted];
    asl_log(NULL, NULL, ASL_LEVEL_ERR, "MADocument Error (Show UI %s): %s\n\t%s",
            userInteractionPermitted ? "YES" : "NO", error.localizedFailureReason.UTF8String,
            error.localizedDescription.UTF8String);
    NSArray *detailErrors;
    if((detailErrors = [error.userInfo objectForKey:NSDetailedErrorsKey]).count > 0) {
        for (NSError *detailError in detailErrors) {
            asl_log(NULL, NULL, ASL_LEVEL_ERR, "  Error: %s\n\t%s",
                    detailError.localizedFailureReason.UTF8String,
                    detailError.localizedDescription.UTF8String);
        }
    }
}

#pragma mark -
#pragma mark Writing

- (BOOL)writeContents:(id)contents
        andAttributes:(NSDictionary *)additionalFileAttributes
          safelyToURL:(NSURL *)url
     forSaveOperation:(UIDocumentSaveOperation)saveOperation
                error:(NSError * __autoreleasing *)outError {
    
    BOOL success;
    NSError * __autoreleasing error = nil;
    if (!(success = [super writeContents: contents
                           andAttributes: additionalFileAttributes
                             safelyToURL: self.urlGuts
                        forSaveOperation: saveOperation
                                   error: &error])) {
        if (*outError != nil) {
            *outError = error;
        }
        return NO;
    }
    MADArchiveManager *archiveManager;
    archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: self.urlGuts
                                                            archiveURL: self.fileURL];
    return [archiveManager archive:YES];
}

- (NSDictionary *)fileAttributesToWriteToURL: (NSURL *)url
                            forSaveOperation: (UIDocumentSaveOperation)saveOperation
                                       error: (NSError * __autoreleasing *)outError {
    id fileAttributes;
    if (self.thumbnail != nil) {
        UIImage *thumbnail = self.thumbnail.copy;
        NSDictionary *thumbnails = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    thumbnail, NSThumbnail1024x1024SizeKey, nil];
        thumbnail = nil;
        
        fileAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                thumbnails, NSURLThumbnailDictionaryKey, nil];
    } else {
        fileAttributes = @{};
    }
    
    
    return fileAttributes;
}


- (NSString *)fileNameExtensionForType: (NSString *)typeName
                         saveOperation: (UIDocumentSaveOperation)saveOperation {
    return MADFileExtentionMobleApplicationDocument;
}

- (void)autosaveWithCompletionHandler:(void (^ __nullable)(BOOL success))completion {

    if ([self hasUnsavedChanges]) {
        
        [self saveToURL: self.fileURL
       forSaveOperation: UIDocumentSaveForOverwriting
      completionHandler: completion];
        
    } else {
        completion(YES);
    }
    
}

#pragma mark -
#pragma mark MADocument Overrides

- (void)setDatabase:(MTDatabase *)database {
    if (_database != database) {
        _database = database;
        _database.delegate = self;
    }
}

#pragma mark -
#pragma mark UIManagedDocument Overrides

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL
                               error:(NSError * __autoreleasing *)error {

    NSError *readError = nil;

    NSData *imageData = nil;
    NSURL *thumbnailURL = [self thumbnailURL];
    NSString *path = thumbnailURL.path;
    if (path) {
        if ([[NSFileManager defaultManager] fileExistsAtPath: path]) {
            imageData = [NSData dataWithContentsOfURL: thumbnailURL
                                              options: NSDataReadingUncached
                                                error: &readError];
        }
    }
    
    if (imageData != nil) {
        UIImage *image = [UIImage imageWithData: imageData];
        
        if (image != nil) {

            UIImage *extraImage = [UIImage imageWithData:imageData];
            NSString *key = [UIScreen mainScreen].isRetnaDisplay ?
                                    MADDocumentInfoKeyThumbnailRetna :
                                    MADDocumentInfoKeyThumbnailStandard;
            self.extraInformation[key] = extraImage;
            extraImage = nil;
        }
        image = nil;
    }
    
    NSDictionary *dicionary = [[NSDictionary alloc] initWithContentsOfURL:self.urlMetaPlaylist];
    NSString *infoKeyGenerator = dicionary[MADDocumentInfoKeyGenerator];
    NSString *lastGenerator = infoKeyGenerator.copy;
    NSNumber *lastVersion = ((NSNumber *)dicionary[MADDocumentInfoKeyVersion]).copy;
    
    if (lastGenerator == nil) {
        NSString *generator = @"MAD Designer";
        lastGenerator = generator;
    }
    
    if (lastVersion == nil) {
        NSNumber *lastDocVersoin = [[NSNumber alloc] initWithDouble:1.0];
        lastVersion = lastDocVersoin;
    }
    
    self.extraInformation[MADDocumentInfoKeyGenerator] = lastGenerator;
    self.extraInformation[MADDocumentInfoKeyVersion] = lastVersion;
    
    return YES;
}

- (id)additionalContentForURL:(NSURL *)absoluteURL error:(NSError * __autoreleasing *)error {

    if (self.extraInformation == nil) {
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] initWithCapacity:3];
        self.extraInformation = extraInfo;
    }
    NSNumber *dataVersion = [[NSNumber alloc] initWithDouble:1.0];
    self.extraInformation[MADDocumentInfoKeyVersion] = dataVersion;
    self.extraInformation[MADDocumentInfoKeyGenerator] = @"MAD Designer";
    return self.extraInformation;
}

- (BOOL)writeAdditionalContent: (id)content
                         toURL: (NSURL *)absoluteURL
           originalContentsURL: (NSURL *)absoluteOriginalContentsURL
                         error: (NSError * __autoreleasing *)error {
    
    BOOL writeAdditionalContent = [super writeAdditionalContent: content
                                                          toURL: absoluteURL
                                            originalContentsURL: absoluteOriginalContentsURL
                                                          error: error];

    if (content == [NSNull null] || self.documentStatus.isSuspended) {
        
        writeAdditionalContent  = NO;
        
    } else if (content != nil) {
        
        writeAdditionalContent  = YES;
        
        NSDictionary *additionalContent;
        id version = content[MADDocumentInfoKeyVersion];
        id generator = content[MADDocumentInfoKeyGenerator];
        
        additionalContent = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           version, MADDocumentInfoKeyVersion,
                                           generator, MADDocumentInfoKeyGenerator, nil];
        if (![additionalContent writeToURL:_urlMetaPlaylist atomically:NO])
            NSLog(@"Write to %@ failed", _urlMetaPlaylist);
    } else {
        
        writeAdditionalContent = NO;
        
    }
    return writeAdditionalContent;
}

+ (NSString *)persistentStoreName { return MADPersistentStoreAliasMad; }

#pragma mark -
#pragma mark UIPrintInteractionControllerDelegate

- (void)printInteractionControllerWillPresentPrinterOptions:(UIPrintInteractionController *)ic { }
- (void)printInteractionControllerWillDismissPrinterOptions:(UIPrintInteractionController *)ic { }
- (void)printInteractionControllerDidPresentPrinterOptions:(UIPrintInteractionController *)ic { }
- (void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)ic { }

- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController *)controller {
    self.printingReportFormatter.dataDelegate = self;
    self.printingReportFormatter.layoutSize = controller.printPaper.paperSize;
    self.printingReportFormatter.marginUsingPrintableRect = controller.printPaper.printableRect;
    self.printingReportFormatter.didRefresh = YES;
    [self.printingReportFormatter formatForSize: controller.printPaper.paperSize
                                 contentChanged: NO];
}
- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)controller {
    self.printingReportFormatter = nil;
}

- (void)updatePrintingReportFormatter {
    MADReportFormatter *reportFormatter;
    reportFormatter = [MADReportFormatter newReportFormatterWithLayout: self
                                                               options: MADReportFormatterOptionsMargin];
    reportFormatter.overrideIdentifier = @"madprinter";
    self.printingReportFormatter = reportFormatter;
}

#pragma mark -
#pragma mark Query Building

- (void)addQuerySelectTableForSchemeTableWithObjectID:(NSManagedObjectID *)objectID {

    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.managedObjectContext;
    [private performBlockAndWait: ^{

        RptqDatabaseSchemaTable *schemaTable = [private objectWithID:objectID];
        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *query = rptqDatabase.hasQueries.anyObject;
        
        RptqQueryTable *newQueryTable = [RptqQueryTable newQueryTableForSchemaTable: schemaTable
                                                                           database: rptqDatabase
                                                            forManagedObjectContext: private];
        newQueryTable.inQuery = query;
        
        NSMutableSet <RptqQueryTable *> *tablesInQuery;
        NSMutableSet <RptqQueryField *> *newQueryFields;
        tablesInQuery = query.hasQueryTables.mutableCopy;
        newQueryFields = [[NSMutableSet alloc] initWithCapacity: schemaTable.hasFields.count];
        
        for (RptqDatabaseSchemaField *field in schemaTable.hasFields) {
            @autoreleasepool {
                
                RptqQueryField *newQueryField = [RptqQueryField newQueryField:private];
                newQueryField.inQueryTable = newQueryTable;
                newQueryField.databaseSchemaField = field;
                [newQueryFields addObject:newQueryField];
                
            }
        }
        newQueryTable.hasQueryFields = newQueryFields;
        
        [tablesInQuery addObject:newQueryTable];
        query.hasQueryTables = tablesInQuery;
        
        NSError * __autoreleasing error = NULL;
        [private save:&error];
        [private refreshObject:newQueryTable mergeChanges:NO];
        
        for (RptqQueryField *field in newQueryFields) {
            RptqQueryTable *table = field.inQueryTable;
            if (field.inQueryTable != nil) {
                [private refreshObject: table mergeChanges:NO];
            }
            RptqDatabaseSchemaField *schemaField = field.databaseSchemaField;
            [private refreshObject: schemaField    mergeChanges:NO];
            [private refreshObject: field          mergeChanges:NO];
        }

        for (RptqDatabaseSchemaField *field in schemaTable.hasFields) {
            [private refreshObject:field mergeChanges:NO];
        }

        [private refreshObject:query mergeChanges:NO];
        [private refreshObject:rptqDatabase mergeChanges:NO];
        [private refreshObject:rptqDocument mergeChanges:NO];

        [tablesInQuery removeAllObjects];
        [newQueryFields removeAllObjects];

    }];
    
}

- (void)addQueryGroupWithQueryField: (NSManagedObjectID *)queryFieldObjectID
                       andSortOrder: (MADSortOrder)sortOrder; {

    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.managedObjectContext;

    [private performBlockAndWait: ^{
        
        RptqQueryField *queryField = [private objectWithID:queryFieldObjectID];
        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        
        
        RptqQueryGroup *queryGroup = [RptqQueryGroup newQueryGroupQueryWithSortOrder: sortOrder
                                                             andManagedObjectContext: private];
        
        queryGroup.hasField = queryField;   //Retain cycle
        
        //Create group header (contains a retain cycle)
        RptqDocumentSection *headerSection;
        headerSection = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupHeader
                                              forManagedObjectContext: private];
                                                                   
        RptqDocumentSectionRows *headerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:private];
        headerSectionRow.inSection = headerSection;
        
        NSMutableOrderedSet *headerSectionRows = [[NSMutableOrderedSet alloc] initWithObject: headerSectionRow];
        headerSection.hasRows = headerSectionRows;
        
        [queryGroup addHasSectionObject:headerSection];
        
        //Create group footer (contains a retain cycle)
        RptqDocumentSection *footerSection;
        footerSection = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupFooter
                                              forManagedObjectContext: private];
        RptqDocumentSectionRows *footerSectionRow;
        footerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext: private];
        footerSectionRow.inSection = footerSection;
        
        NSMutableOrderedSet *footerSectionRows;
        footerSectionRows = [[NSMutableOrderedSet alloc] initWithObject: footerSectionRow];
        footerSection.hasRows = footerSectionRows;
        
        [queryGroup addHasSectionObject:footerSection];
        
        
        MADSectionLayoutManager *layoutManagerHeader;
        layoutManagerHeader = [[MADSectionLayoutManager alloc] initWithDocumentSection:headerSection];
        NSNumber *key = @(headerSection.identifier);
        self.sectionLayoutManagers[key] = layoutManagerHeader;
        
        MADSectionLayoutManager *layoutManagerFooter;
        layoutManagerFooter = [[MADSectionLayoutManager alloc] initWithDocumentSection:footerSection];
        key = @(footerSection.identifier);
        self.sectionLayoutManagers[key] = layoutManagerFooter;


        RptqDatabase *database = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *query = database.hasQueries.anyObject;
        [query addHasQueryGroupsObject: queryGroup];

        NSError * __autoreleasing error = NULL;
        [private save:&error];
        
        RptqQueryField *groupByField = queryGroup.hasField;
        if (groupByField) {
            [private refreshObject:groupByField mergeChanges:NO];
        }
        [private refreshObject:queryGroup mergeChanges:NO];
        
        RptqDocumentSection *header;
        if ((header = headerSectionRow.inSection)) {
            [private refreshObject:header mergeChanges:NO];
        }
        
        RptqDocumentSection *footer;
        if ((footer = footerSectionRow.inSection)) {
            [private refreshObject:footer mergeChanges:NO];
        }
        
        [private refreshObject:headerSectionRow mergeChanges:NO];
        [private refreshObject:footerSectionRow mergeChanges:NO];
        [private refreshObject:headerSection mergeChanges:NO];
        [private refreshObject:footerSection mergeChanges:NO];
        
        [private refreshObject:query mergeChanges:NO];
        [private refreshObject:database mergeChanges:NO];
        [private refreshObject:queryGroup mergeChanges:NO];
        [private refreshObject:rptqDocument mergeChanges:NO];
        [private refreshObject:queryField mergeChanges:NO];

        [headerSectionRows removeAllObjects];
        [footerSectionRows removeAllObjects];

    }];

}

#pragma mark -
#pragma mark NSManagedObjectContext Notifications

- (void)handleManagedObjectContextDidChange:(NSNotification *)notification {
    //NSSet *updated = notification.userInfo[NSUpdatedObjectsKey];
    self.documentStatus.needsSave = YES;
    self.documentStatus.contextChagned = YES;
}

- (void)handleManagedObjectContextDidSave:(NSNotification *)notification {
    self.documentStatus.saveInProgress = NO;
    self.documentStatus.needsSave = NO;
}

- (void)handleManagedObjectContextWillSave:(NSNotification *)notification {
    self.documentStatus.saveInProgress = YES;
}

#pragma mark - UIDocument Notifications

- (void)handleDocumentStateChanged:(NSNotification *)notification {

    if (notification.object != nil) {
        switch (((MADocument *)notification.object).documentState) {
            case UIDocumentStateClosed:
                NSLog(@"\n\n\tDocument state closed.\n\n");
                break;
            case UIDocumentStateEditingDisabled:
                NSLog(@"\n\n\tDocument state editing disabled.\n\n");
                break;
            case UIDocumentStateInConflict:
                NSLog(@"\n\n\tDocument state in conflict.\n\n");
                break;
            case UIDocumentStateNormal:
                NSLog(@"\n\n\tDocument state normal.\n\n");
                break;
            case UIDocumentStateSavingError:
                NSLog(@"\n\n\tDocument state saving error.\n\n");
                break;
            case UIDocumentStateProgressAvailable:
                NSLog(@"Document progress: %@", notification);
                break;
            default:
                break;
        }
    }
}

#pragma mark - Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    NSDictionary *parameters = sender.userInfo;
    NSNumber *pageNumber = parameters[MTDatabaseNumberOfPagesFormattedKey];
    
    NSString *decimalString;
    decimalString = [NSNumberFormatter localizedStringFromNumber: pageNumber
                                                     numberStyle: NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Formatted page %@.", @"Formatted page %@.");
    NSString *readRecords = [[NSString alloc] initWithFormat:formatString, decimalString];
    [self.documentStatusProtocol performSelectorOnMainThread: @selector(setStatusText:)
                                                  withObject: readRecords
                                               waitUntilDone: NO];
}

#pragma mark - MADDatabaseProtocol

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    MADCredential *credentials = [self.documentDelegate getCredentialsForKey:key];
    return credentials;
}

- (MADDataTable *)dataTableForQuery:(MTQuery *)query {

    switch (query.type) {
        
        case MADQueryTypeFull:
            self.dataTable.dataDelegate = self;
            return self.dataTable;
            break;
    
        default:
            return nil;
            break;
    }
}

#pragma mark - MADReportFormatterDataSource Protocol

- (NSEnumerator *)enumeratorForReportData {
    return [self.dataTable enumeratorForKeyObjectsSorted];
}

- (BOOL)cacheExist {
    NSString *path = self.urlDataTableCache.path;
    return [[NSFileManager defaultManager] fileExistsAtPath: path];
}

- (NSDictionary *)copyDataForCacheId:(NSUInteger)cachedID {
    return  [self.dataTable copyDataForCacheId:cachedID];
}

#pragma mark - Helpers

- (void)saveContext {
    NSError *error;
    if (self.managedObjectContext != nil) {
        if ((self.managedObjectContext).hasChanges && ![self.managedObjectContext save:&error]) {
            NSLog(@"Error saving managed object context: %@", error);
            [self.managedObjectContext save:nil];
        }
    }
}

- (MTPaper *)paper {
    if (_paper == nil) {
        RptqDocument *document = [self activeDocumentModel];
        MTPaper *paper = [[MTPaper alloc] initWithType: document.paperType];
        self.paper = paper;
    }
    return _paper;
}

- (void)resetPaper {
    self.paper = nil;
}

- (RptqDocument *)activeDocumentModel {

    if (_activeDocumentModel == nil) {
        
        RptqDocument *document = nil;
        
        document = [RptqDocument newDocumentReadFromManagedObjectContext: self.managedObjectContext];
        
        [self resetPaper];
        [self resetMainQuery];
        [self resetSectionLayoutManagers];
        [self resetReportFormatter];
        
        _activeDocumentModel = document;
        
    }
    return _activeDocumentModel;
}

- (NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *)sectionLayoutManagers {
    if (_sectionLayoutManagers.count == 0) {
        NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *sectionLayoutManagers;
        RptqDocumentSectionEnumerator *sections;
        MADSectionLayoutManager *layoutManager;
        NSNumber *identifier;
        
        sectionLayoutManagers = [[NSMutableDictionary alloc] init];
        sections = [[RptqDocumentSectionEnumerator alloc] initWithDocument:self.activeDocumentModel];
        for (RptqDocumentSection *reportSection in sections) {
            layoutManager = [[MADSectionLayoutManager alloc] initWithDocumentSection:reportSection];
            identifier = @(reportSection.identifier);
            sectionLayoutManagers[identifier] = layoutManager;
        }
        
        _sectionLayoutManagers = sectionLayoutManagers;
    }
    return _sectionLayoutManagers;
}

- (void)resetSectionLayoutManagers {
    [_sectionLayoutManagers removeAllObjects];
}

- (void)removeDocumentObjectWithObjectID:(int64_t)objectID {

    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.managedObjectContext;
    [private performBlockAndWait: ^{

        RptqDocumentElement *element;
        element = [RptqDocumentElement newDocumentElementWithIdentifier:objectID
                                                      fromObjectContext:private];
        RptqDocumentSection *parentSection = element.inSectionRow.inSection;
        MADSectionLayoutManager *layoutManager;
        NSNumber *key = @(parentSection.identifier);
        layoutManager = self.sectionLayoutManagers[key];
        [RptqDocumentElement removeDocumentObject: element
                                fromParentSection: parentSection
                                withLayoutManager: layoutManager];

        NSError * __autoreleasing error = NULL;
        if (![private save:&error]) NSLog(@"Error saving context: %@.", error);
    }];

}

- (void)deleteAggregateFieldRelatedToTable: (NSManagedObjectID *)deleatedTableObjectID
                                 inContent: (NSManagedObjectContext *)managedObjectContext {
    NSString *entityName = NSStringFromClass([RptqDocumentElement class]);
    NSFetchRequest *fetchReqest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSString *keyInQueryTable, *keyInQueryTableRel;
    
    keyInQueryTableRel = NSStringFromSelector(@selector(inQueryTable));
    
    keyInQueryTable = [NSStringFromSelector(@selector(aggregateField)) stringByAppendingPeriod];
    keyInQueryTable = [keyInQueryTable stringByAppendingString:keyInQueryTableRel];
    
    NSPredicate *predicate = [NSPredicate newPredicateObjectWithObjectID: deleatedTableObjectID
                                                               atKeyPath: keyInQueryTable];

    fetchReqest.predicate = predicate;
    NSError *fetchError = nil;
    NSArray *objectsToDelete = [managedObjectContext executeFetchRequest:fetchReqest error:&fetchError];
    if (fetchError == nil) {
        RptqDocumentElement *documentObject; RptqDocumentSection *parentSection;
        MADSectionLayoutManager *layoutManager;
        for (documentObject in objectsToDelete) {
            parentSection = documentObject.inSectionRow.inSection;
            NSNumber *key = @(parentSection.identifier);
            layoutManager = self.sectionLayoutManagers[key];
            [RptqDocumentElement removeDocumentObject:documentObject
                                    fromParentSection:parentSection
                                    withLayoutManager:layoutManager];
            [managedObjectContext deleteObject:documentObject];
        }
    }
}

- (void)deleteDatafieldsRelatedToTable: (NSManagedObjectID *)deleatedTableObjectID
                             inContent: (NSManagedObjectContext *)managedObjectContext {
    NSString *entityName = NSStringFromClass([RptqDocumentElement class]);
    NSFetchRequest *fetchReqest;
    fetchReqest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSString *keyInQueryTable = [NSStringFromSelector(@selector(referencesQueryField)) stringByAppendingPeriod];
    keyInQueryTable = [keyInQueryTable stringByAppendingString:NSStringFromSelector(@selector(inQueryTable))];
    
    NSPredicate *predicate = [NSPredicate newPredicateObjectWithObjectID: deleatedTableObjectID
                                                               atKeyPath: keyInQueryTable];
    fetchReqest.predicate = predicate;
    NSError *fetchError = nil;
    NSArray *objectsToDelete = [managedObjectContext executeFetchRequest:fetchReqest
                                                                   error:&fetchError];
    if (fetchError == nil) {
        
        RptqDocumentSection *parentSection;
        MADSectionLayoutManager *layoutManager;
        for (RptqDocumentElement *documentObject in objectsToDelete) {
            parentSection = documentObject.inSectionRow.inSection;

            NSNumber *key = @(parentSection.identifier);
            layoutManager = self.sectionLayoutManagers[key];
            [RptqDocumentElement removeDocumentObject: documentObject
                                    fromParentSection: parentSection
                                    withLayoutManager: layoutManager];
            [managedObjectContext deleteObject:documentObject];
        }
    }
}

- (void)removeGroupWitObjectID:(NSManagedObjectID *)groupID
      fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    //NSManagedObjectContext *private;
    // = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    //private.parentContext = managedObjectContext;
    
    //[private performBlockAndWait: ^{
        
        RptqQueryGroup *group = [managedObjectContext objectWithID:groupID];
        if (group) {
            RptqQuery *query = group.inQuery;
            
            NSArray *sections = group.hasSection.allObjects;
            NSAssert(sections.count == 2, @"Expecting a header and footer.");
            
            RptqDocumentSection *section0 = sections[0];
            RptqDocumentSection *section1 = sections[1];
            
            NSNumber *key = @(section0.identifier);
            [self.sectionLayoutManagers removeObjectForKey:key];

            key = @(section1.identifier);
            [self.sectionLayoutManagers removeObjectForKey:key];
            
            [group removeHasSectionObject: section0];
            [group removeHasSectionObject: section1];
            
            [query.managedObjectContext deleteObject: group];
            [query removeHasQueryGroupsObject: group];
            
            //Reweight Groups
            SEL weightSelector = @selector(weight);
            NSSortDescriptor *sort;
            sort = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(weightSelector)
                                                 ascending: YES];
            
            NSArray <NSSortDescriptor *> *sortDescriptors;
            sortDescriptors = [[NSArray alloc] initWithObjects: sort, nil];
            NSArray <RptqQueryGroup *> *sortedGroups;
            sortedGroups = [query.hasQueryGroups sortedArrayUsingDescriptors:sortDescriptors];
            
            int16_t counter = 0;
            for (RptqQueryGroup *sortedGroup in sortedGroups) {
                sortedGroup.weight = counter;
                counter++;
            }
            
        }
        
        NSError * __autoreleasing error = NULL;
        if (![managedObjectContext save:&error]) NSLog(@"Error saving context: %@.", error);
    //}];
    

}

- (MTQuery *)mainQuery {
    if (!_mainQuery) {
        RptqDocument *document = [self activeDocumentModel];
        RptqDatabase *database = document.defaultDatabase;
        if (database) {
            
            RptqQuery *rquery = database.defaultQuery;
            MTQueryFull *mainQuery;
            mainQuery = [[MTQueryFull alloc] initWithQuery: rquery
                                             andQueryLimit: self.limitResultsDesignMode ?
                                                                    50 : NSUIntegerMax];
            mainQuery.dataDelegate = self;
            
            NSArray *sortDescriptors = [self readCurrentSortDescriptors];
            [self.dataTable sortUsingDescriptors:sortDescriptors];
            
            _mainQuery = mainQuery;
        }
    }
    return _mainQuery;
}

- (void)resetMainQuery {
    self.mainQuery = nil;
}

- (MADReportFormatter *)reportFormatter {
    if (!_reportFormatter) {
        MADReportFormatter *formatter;
        formatter = [[MADReportFormatter alloc] initWithDocument: self
                                                         options: MADReportFormatterOptionsNone];
        _reportFormatter = formatter;
    }
    return _reportFormatter;
}

- (void)resetReportFormatter {
    self.reportFormatter = nil;
}

- (MTDatabase *)database {
    if (!_database) {
        RptqDocument *document = [self activeDocumentModel];
        [self initializeMainDatabase:document];
    }
    return _database;
}

- (void)initializeMainDatabase:(RptqDocument *)document {
    RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
    MADDatabaseConnection *connection;
    RptqDatabaseCredentals *ownedByUser = database.ownedByUser;
    connection = [MADDatabaseConnection newDatabaseConnectionForObject: ownedByUser];
    MTDatabase *db = [MTDatabase newDatabaseWithConnection:connection];
    db.delegate = self;
    self.database = db;
}

- (void)prepareForQuery {
    NSArray *sortDescriptors = [self readCurrentSortDescriptors];
    [self.dataTable sortUsingDescriptors:sortDescriptors];
}

- (void)notifyThumbnailUpdated {
    MADNotificationFileUpdate *fileUpdate = [[MADNotificationFileUpdate alloc] init];
    [fileUpdate notify];
}

- (NSArray *)sortDescriptors{
    return [self readCurrentSortDescriptors];
}

- (NSArray *)readCurrentSortDescriptors {
    RptqDocument *document = self.activeDocumentModel;
    if (self.database == nil) {
        [self initializeMainDatabase:document];        // FIXME: I doubt this ever runs.
    }
    return [document.defaultDatabase.defaultQuery sortDescriptorsForDatabase:self.database];
}

- (NSURL *)copyPersistentStoreURL {
    NSPersistentStoreCoordinator *persistentStoreCoordinator =
        self.managedObjectContext.persistentStoreCoordinator;
    NSPersistentStore *persistentStore = persistentStoreCoordinator.persistentStores.lastObject;
    NSURL *storeURL = [persistentStoreCoordinator URLForPersistentStore:persistentStore];
    return storeURL.copy;
}

#pragma mark -
#pragma mark Public

- (void)archiveAndRemoveFileWrapper {
    [MADFileUtilities removeFileAndArchiveAtURL:self.urlGuts];
}

#pragma mark -
#pragma mark Helper

- (NSString *)filename {
    NSString *filename = self.fileURL.lastPathComponent.stringByDeletingPathExtension;
    return filename;
}

#pragma mark -
#pragma mark Debugging

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendString:@"-------------------------------\n"];
    [debug appendFormat:@"Filename:\t%@\n", [self filename]];
    [debug appendString:@"-------------------------------\n"];
    return debug;
}

@end
