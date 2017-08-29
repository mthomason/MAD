//
//  MTViewControllerBarcodeExtraMaxicode.m
//  MAD
//
//  Created by Michael Thomason on 11/12/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableViewControllerBarcodeExtraMaxicode.h"

#import <CoreData/NSManagedObjectContext.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>

#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>

#import <CoreData/NSManagedObjectID.h>

#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTable.h>

#import <MADAPI/MADDatabaseConnection.h>

#import <MADCocoaExtensions/NSError+Constructors.h>

#import <MAD/MTKeyChain.h>
#import <MAD/MADocument.h>

#import <MADAPI/MTDatabase.h>

#import <MAD/MTQuery.h>

#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/MADDataTable+Constructor.h>

#import "MADQueryChooseFieldController.h"

@interface MTTableViewControllerBarcodeExtraMaxicode ()

    @property (nonatomic, strong) MADDataTable *dataTableSampleData;

@end

@implementation MTTableViewControllerBarcodeExtraMaxicode

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger row = [self.delegate initalEncodingMode];
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[MADQueryChooseFieldController class]]) {
        ((MADQueryChooseFieldController *)segue.destinationViewController).delegate = self;
        MADocument *document = self.document;
        [(segue.destinationViewController) setDocument: document];
    }
}

#pragma mark - MADQueryChooseFieldProtocol

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
                                    withFieldID: (NSManagedObjectID *)fieldID {
    
    NSManagedObjectContext *context = self.document.managedObjectContext;
    RptqQueryField *field = [context objectWithID: fieldID];
    
    [self.navigationController popViewControllerAnimated:YES];
    
    RptqDatabaseSchemaField *schemaField = field.databaseSchemaField;
    MADDataTable *dataTable = [MTTableViewControllerBarcodeExtraMaxicode newDataTableForMangedObject:schemaField.objectID];
    self.dataTableSampleData = dataTable;
    MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType: MADQueryTypeSampleDataField
                                                                object: schemaField];
    NSError * __autoreleasing error = NULL;
    BOOL success = [querySampleDataField performQueryWithError:&error];
    if (success) {
        MADDataTable * __autoreleasing dt = [querySampleDataField.database.delegate dataTableForQuery:querySampleDataField];
        self.dataTableSampleData = dt;
        NSArray *allObjects = [self.dataTableSampleData allObjects];
        [self.delegate barcodeMaxicodeDidChooseSampleData:allObjects];
        [self.tableView reloadData];
    } else {
        MTTableViewControllerBarcodeExtraMaxicode * __weak wself = self;
        [NSError presentError: error
             onViewController: wself
                   completion:^(BOOL presentErrorSuccess) {
                       NSString *key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
                       [MTKeyChain deleteKey:key];
                   }];
        
    }
}

+ (MADDataTable *)newDataTableForMangedObject:(NSManagedObjectID *)objectID {
    NSUInteger hash = objectID.URIRepresentation.absoluteString.hash;
    NSNumber *typeKey = @(MADDataTableParametersType);
    NSNumber *type = @(MADDataTableTypeVirtual);
    NSNumber *objectIdKey = @(MADDataTableParametersIdentifier);
    NSNumber *objectIdV =  @(hash);
    NSDictionary *options = @{typeKey : type,
                              objectIdKey : objectIdV};
    MADDataTable *dataTable = [MADDataTable newDataTableWithDefinition:options];
    return dataTable;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1) {
        NSInteger numberOfRows = [tableView numberOfRowsInSection:1];
        for (NSInteger i = 0; i < numberOfRows; i++) {
            UITableViewCell *c = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
            c.accessoryType = UITableViewCellAccessoryNone;
        }
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.delegate barcodeMaxicodeDidSetEncodingMode:cell.tag];
    }
}

@end
