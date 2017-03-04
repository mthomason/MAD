//
//  InterfaceController.m
//  MAD Designer WatchKit Extension
//
//  Created by Michael Thomason on 3/31/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADInterfaceControllerDocumentsLocal.h"
#import "MADRowTypeDocumentsLocal.h"
#import <Foundation/NSFileManager.h>
#import <MADFileManager/MADFileUtilities.h>

@interface MADInterfaceControllerDocumentsLocal()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *groupMiddle;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *tableMain;

@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonInfo;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonExport;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonMad;

@property (nonatomic, strong) NSArray *filesByURL;

@end


@implementation MADInterfaceControllerDocumentsLocal

- (instancetype)init {
    
    if (self = [super init]) {

        NSString *identifierRowTypeDocumentLocal = NSStringFromClass([MADRowTypeDocumentsLocal class]);
        NSArray *rowTypes = [[NSArray alloc] initWithObjects: identifierRowTypeDocumentLocal, nil];
        [self.tableMain setRowTypes:rowTypes];

        NSArray *files = [MADFileUtilities contentsOfDocumentsDirectoryWithGroupIdentifier: MADIdentifierGroup
                                                                              andExtention: MADFileExtentionMobleApplicationDocument];
        
        
        [self.tableMain setNumberOfRows: files.count
                            withRowType: identifierRowTypeDocumentLocal];

        self.filesByURL = files;

    }
    
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    NSString *MADTitle = @"MAD KPIs";
    NSString *localalizedTitle = NSLocalizedString(MADTitle, MADTitle);
    [self setTitle:localalizedTitle];
    
    NSString *filename;
    MADRowTypeDocumentsLocal *rowController;
    for (NSUInteger i = 0; i < self.filesByURL.count; i++) {
        filename = ((NSURL *)self.filesByURL[i]).path.lastPathComponent;
        rowController = [self.tableMain rowControllerAtIndex:i];
        [rowController.label setText:filename];
        [rowController.label setTextColor:[UIColor blackColor]];
    }
    
}

- (void)willActivate {
    [super willActivate];
}

- (void)didDeactivate {
    [super didDeactivate];
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier
                            inTable:(WKInterfaceTable *)table
                           rowIndex:(NSInteger)rowIndex {
    return self.filesByURL.count > 0 ? self.filesByURL[rowIndex] : nil;
}

@end



