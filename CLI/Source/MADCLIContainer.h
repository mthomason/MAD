//
//  MADCLIContainer.h
//  MAD Designer
//
//  Reads a .mad file's container: the archive, its members and its metadata.
//  Deliberately knows nothing about Core Data or the report model -- this is the
//  layer MAD_FORMAT.md section 7 says a second platform can implement on its own.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MADCLIFormatVersion) {
	MADCLIFormatVersion0 = 0,	// no magic header; bzip2 tar from byte 0
	MADCLIFormatVersion1 = 1,	// 16-byte MADFILE header, then the bzip2 stream
};

/// The fixed facts read out of a SQLite database's own header, without opening it.
typedef struct {
	BOOL		present;
	uint32_t	pageSize;
	uint32_t	pageCount;
	uint32_t	sqliteVersion;	// 3043002 means SQLite 3.43.2
	uint32_t	textEncoding;
	BOOL		writeVersionWAL;	// file format write version == 2
} MADCLISQLiteHeader;

@interface MADCLIContainer : NSObject

/// Unarchives `url` into a private temporary directory.  Nothing is written
/// anywhere else, and the document is never modified.
+ (instancetype)containerWithContentsOfURL:(NSURL *)url error:(NSError **)error;

@property (readonly, nonatomic, copy) NSURL *archiveURL;
@property (readonly, nonatomic) MADCLIFormatVersion formatVersion;
@property (readonly, nonatomic) uint32_t formatFlags;
@property (readonly, nonatomic, copy) NSURL *gutsURL;
@property (readonly, nonatomic, copy) NSDictionary *meta;

@property (readonly, nonatomic, copy) NSURL *storeURL;			// StoreContent/analyitics
@property (readonly, nonatomic, copy) NSURL *walURL;			// may be nil
@property (readonly, nonatomic, copy) NSURL *shmURL;			// may be nil
@property (readonly, nonatomic, copy) NSURL *additionalContentURL;	// may be nil

/// Sorted member paths, relative to the archive root.
@property (readonly, nonatomic, copy) NSArray <NSString *> *memberPaths;

/// Read the SQLite header of the store.  No SQL, no Core Data.
- (MADCLISQLiteHeader)storeHeader;

/// Remove the temporary directory.  Called when the verb is done.
- (void)discard;

@end

/// "3.43.2" from 3043002.
NSString *MADCLISQLiteVersionString(uint32_t versionNumber);
