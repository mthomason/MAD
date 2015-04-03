//
//  InterfaceController.m
//  MAD Designer WatchKit Extension
//
//  Created by Michael Thomason on 3/31/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "InterfaceController.h"
#import "RowTypeDocumentLocal.h"
#import "UIColor+EverydayApps.h"
#import "NSFileManager+Common.h"
#import "MADConstants.h"

@interface InterfaceController()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *groupMiddle;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *tableMain;

@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonInfo;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonExport;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonMad;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    //UIColor *backgroundColor = [UIColor tintColorAnalogous4];
    //[self.groupTop setBackgroundColor:backgroundColor];
    
    [self setTitle:@"MAD KPIs"];
    
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDocumentsDirectoryWithGroupIdentifier: MADIdentifierGroup
                                                                                        andExtention: MADFileExtentionMobleApplicationDocument];
    
    Class rowControllerClassDocumentsLocal = [RowTypeDocumentLocal class];
    NSString *identifierRowTypeDocumentLocal = NSStringFromClass(rowControllerClassDocumentsLocal);
    NSArray *rowTypes = @[identifierRowTypeDocumentLocal];
    [self.tableMain setRowTypes:rowTypes];
    [self.tableMain setNumberOfRows:files.count
                        withRowType:identifierRowTypeDocumentLocal];
    

    RowTypeDocumentLocal *rowController;
    NSString *filename;
    for (int i=0; i<files.count; i++) {
        filename = ((NSURL *)files[i]).path.lastPathComponent;
        rowController = [self.tableMain rowControllerAtIndex:i];
        [rowController.label setText:filename];
        [rowController.label setTextColor:[UIColor blackColor]];
    }
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



