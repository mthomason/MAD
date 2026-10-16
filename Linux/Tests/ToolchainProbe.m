//
//  ToolchainProbe.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  The Phase B toolchain probe (MAD_LINUX.md §9): proves that clang +
//  libobjc2 + GNUstep Foundation can run the language and Foundation features
//  the MAD engine leans on, before any of the engine is judged portable.
//
//  Two sections:
//    core    the features the engine requires -- a failure here fails the run
//    report  the §5.3 unknowns -- printed, never fatal, and the evidence the
//            Phase B status paragraph records for Phase C
//
//  Builds standalone, ARC on:
//    clang `gnustep-config --objc-flags` -fobjc-arc ToolchainProbe.m \
//        -o probe `gnustep-config --base-libs` -ldispatch
//  The link block at the bottom activates only when the MADFoundation headers
//  are on the include path (the CMake build supplies them through the shim).
//

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <objc/message.h>

#if __has_include(<MADFoundation/MADDataColumn.h>)
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>
#import <MADFoundation/MADExclusivityController.h>
#import <MADFoundation/MADGroupOperation.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/MADOperationQueue.h>
#define MAD_PROBE_ENGINE 1
#endif

#pragma mark -
#pragma mark Counters and reporting

static unsigned gCoreChecks;
static unsigned gCoreFailures;
static unsigned gReportOk;
static unsigned gReportNeeds;

static void MADProbeCore(BOOL ok, const char *name) {
	gCoreChecks++;
	if (!ok) gCoreFailures++;
	printf("probe %s: %s\n", name, ok ? "OK" : "FAIL");
}

static void MADProbeReportItem(const char *name, BOOL ok, NSString *detail) {
	if (ok) {
		gReportOk++;
		printf("REPORT %s: OK\n", name);
	} else {
		gReportNeeds++;
		if (detail.length) {
			printf("REPORT %s: NEED - %s\n", name, detail.UTF8String);
		} else {
			printf("REPORT %s: NEED\n", name);
		}
	}
}

static NSString *MADProbeExceptionDetail(NSException *e) {
	return [[NSString alloc] initWithFormat:@"raised %@: %@", e.name, e.reason];
}

// GNUstep's NSKeyedUnarchiver implements neither modern class-keyed entry
// point, so the probe has to ask at runtime and send through objc_msgSend.
typedef id (*MADProbeUnarchiveFn)(Class, SEL, Class, NSData *, NSError **);
typedef id (*MADProbeUnarchiveLegacyFn)(Class, SEL, NSData *, NSError **);

#pragma mark -
#pragma mark Helpers

// KVO observation target.
@interface MADProbeObserver : NSObject
@property (nonatomic) NSUInteger count;
@end

@implementation MADProbeObserver

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	self.count = self.count + 1;
}

@end

// KVO subject with a dependent key -- the MADOperation pattern.
@interface MADProbeSubject : NSObject
@property (nonatomic) NSInteger value;
@property (nonatomic) NSInteger derived;
@end

@implementation MADProbeSubject

+ (NSSet *)keyPathsForValuesAffectingDerived {
	return [NSSet setWithObject:@"value"];
}

@end

// Asynchronous operation driving isExecuting/isFinished with manual KVO --
// the MADOperation pattern.
@interface MADProbeAsyncOperation : NSOperation
@end

@implementation MADProbeAsyncOperation {
	BOOL _probeExecuting;
	BOOL _probeFinished;
}

- (BOOL)isAsynchronous { return YES; }
- (BOOL)isConcurrent { return YES; } // the GNUstep-era spelling

- (BOOL)isExecuting { return _probeExecuting; }
- (BOOL)isFinished { return _probeFinished; }

- (void)start {
	if (self.isCancelled) {
		[self willChangeValueForKey:@"isFinished"];
		_probeFinished = YES;
		[self didChangeValueForKey:@"isFinished"];
		return;
	}
	[self willChangeValueForKey:@"isExecuting"];
	_probeExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[NSThread sleepForTimeInterval:0.05];
		[self willChangeValueForKey:@"isExecuting"];
		[self willChangeValueForKey:@"isFinished"];
		self->_probeExecuting = NO;
		self->_probeFinished = YES;
		[self didChangeValueForKey:@"isExecuting"];
		[self didChangeValueForKey:@"isFinished"];
	});
}

@end

// A secure-coding value object -- the MADCredential/MADDataColumn pattern.
@interface MADProbeBox : NSObject <NSSecureCoding>
@property (nonatomic, copy) NSString *text;
- (instancetype)initWithText:(NSString *)text;
@end

@implementation MADProbeBox

+ (BOOL)supportsSecureCoding { return YES; }

- (instancetype)initWithText:(NSString *)text {
	if (self = [super init]) {
		_text = [text copy];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	return [self initWithText:[coder decodeObjectOfClass:[NSString class] forKey:@"text"]];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:_text forKey:@"text"];
}

@end

// A row with an optional error -- the predicate MADOperationConditionResult
// evaluates for real.
@interface MADProbeRow : NSObject
@property (nonatomic, strong) NSError *error;
@end

@implementation MADProbeRow
@end

// Runs the run loop until the condition is true or the timeout elapses.
static BOOL MADProbeWaitFor(BOOL (^condition)(void), NSTimeInterval timeout) {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
	while (!condition() && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
	return condition();
}

#pragma mark -
#pragma mark Core checks

static void MADProbeCoreChecks(void) {
	// ARC: a weak reference nils when its object dies.
	__weak NSObject *weakRef = nil;
	@autoreleasepool {
		NSObject *strong = [[NSObject alloc] init];
		weakRef = strong;
		MADProbeCore(weakRef != nil, "weak-alive");
	}
	MADProbeCore(weakRef == nil, "weak-zeroing");

	// Blocks: capture, __block mutation, copy to the heap.
	__block NSInteger captured = 1;
	NSInteger (^adder)(NSInteger) = ^(NSInteger y) {
		captured += y;
		return captured;
	};
	NSInteger (^heapBlock)(NSInteger) = [adder copy];
	MADProbeCore(heapBlock(2) == 3 && captured == 3 && adder(1) == 4, "blocks");

	// Exceptions with ARC in the frame.
	BOOL caught = NO;
	BOOL finallyRan = NO;
	@try {
		[NSException raise:@"MADProbe" format:@"probe"];
	} @catch (NSException *e) {
		caught = [e.reason isEqualToString:@"probe"];
	} @finally {
		finallyRan = YES;
	}
	MADProbeCore(caught && finallyRan, "exceptions");

	// @synchronized under real concurrency.
	NSObject *lock = [[NSObject alloc] init];
	__block NSInteger total = 0;
	dispatch_apply(4, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
		for (NSInteger j = 0; j < 250; j++) {
			@synchronized (lock) {
				total++;
			}
		}
	});
	MADProbeCore(total == 1000, "synchronized");

	// KVO: manual notification on a plain key.
	MADProbeSubject *subject = [[MADProbeSubject alloc] init];
	MADProbeObserver *observer = [[MADProbeObserver alloc] init];
	[subject addObserver:observer forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:NULL];
	subject.value = 7;
	[subject removeObserver:observer forKeyPath:@"value"];
	MADProbeCore(observer.count == 1, "kvo");

	// NSOperationQueue and block operations.
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 2;
	NSLock *counterLock = [[NSLock alloc] init];
	__block NSInteger ran = 0;
	for (NSInteger i = 0; i < 4; i++) {
		[queue addOperationWithBlock:^{
			[counterLock lock];
			ran++;
			[counterLock unlock];
		}];
	}
	[queue waitUntilAllOperationsAreFinished];
	MADProbeCore(ran == 4, "nsoperation-queue");

	// dispatch: once, serial ordering, group, semaphore.
	static dispatch_once_t onceToken;
	__block NSInteger onceCount = 0;
	dispatch_apply(8, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
		dispatch_once(&onceToken, ^{
			onceCount++;
		});
	});
	MADProbeCore(onceCount == 1, "dispatch-once");

	dispatch_queue_t serial = dispatch_queue_create("MADProbe.serial", DISPATCH_QUEUE_SERIAL);
	NSMutableArray *order = [NSMutableArray array];
	for (NSInteger i = 0; i < 5; i++) {
		dispatch_sync(serial, ^{
			[order addObject:@(i)];
		});
	}
	MADProbeCore(order.count == 5 && [order[0] integerValue] == 0 && [order[4] integerValue] == 4, "dispatch-serial");

	dispatch_group_t group = dispatch_group_create();
	__block NSInteger grouped = 0;
	for (NSInteger i = 0; i < 8; i++) {
		dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			@synchronized (lock) {
				grouped++;
			}
		});
	}
	long groupWait = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)));
	MADProbeCore(groupWait == 0 && grouped == 8, "dispatch-group");

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		dispatch_semaphore_signal(semaphore);
	});
	long semWait = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)));
	MADProbeCore(semWait == 0, "dispatch-semaphore");

	// Foundation basics the engine assumes.
	NSDictionary *dict = @{ @"name": @"MAD", @"rows": @[ @1, @2 ] };
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
	id jsonBack = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL] : nil;
	MADProbeCore([jsonBack isKindOfClass:[NSDictionary class]]
				 && [[jsonBack objectForKey:@"name"] isEqualToString:@"MAD"], "json");

	NSUUID *uuidA = [NSUUID UUID];
	NSUUID *uuidB = [NSUUID UUID];
	MADProbeCore(uuidA != nil && uuidB != nil
				 && ![uuidA.UUIDString isEqualToString:uuidB.UUIDString]
				 && uuidA.UUIDString.length == 36, "uuid");

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	formatter.dateFormat = @"yyyy-MM-dd";
	NSDateComponents *components = [[NSDateComponents alloc] init];
	components.year = 2026;
	components.month = 10;
	components.day = 6;
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	NSDate *fixedDate = [calendar dateFromComponents:components];
	MADProbeCore(fixedDate != nil && [[formatter stringFromDate:fixedDate] isEqualToString:@"2026-10-06"], "date-format");

	NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
	id plistBack = plistData ? [NSPropertyListSerialization propertyListWithData:plistData options:0 format:NULL error:NULL] : nil;
	MADProbeCore([plistBack isKindOfClass:[NSDictionary class]]
				 && [[plistBack objectForKey:@"name"] isEqualToString:@"MAD"], "plist-xml");

	__block BOOL notified = NO;
	id token = [[NSNotificationCenter defaultCenter] addObserverForName:@"MADProbeNote" object:nil queue:nil usingBlock:^(NSNotification *note) {
		notified = [note.name isEqualToString:@"MADProbeNote"];
	}];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MADProbeNote" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:token];
	MADProbeCore(notified, "notification");

	NSString *formatted = [[NSString alloc] initWithFormat:@"%s/%@/%lu/%d", "cstring", @"object", (unsigned long)7, 42];
	MADProbeCore([formatted isEqualToString:@"cstring/object/7/42"], "format");

	NSArray *numbers = @[ @(42), @(3.5), @YES ];
	NSData *numbersData = [NSPropertyListSerialization dataWithPropertyList:numbers format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
	NSArray *numbersBack = numbersData ? [NSPropertyListSerialization propertyListWithData:numbersData options:0 format:NULL error:NULL] : nil;
	MADProbeCore(numbersBack.count == 3 && [numbersBack[0] integerValue] == 42
				 && [numbersBack[2] boolValue] == YES, "number-literal");

#if MAD_PROBE_ENGINE
	// Link check: forces the archive members no test may exercise.
	MADProbeCore([MADDataTable class] != Nil
				 && [MADDataColumn class] != Nil
				 && [MADDataTableVirtual class] != Nil
				 && [MADCredential class] != Nil
				 && [MADExclusivityController class] != Nil
				 && [MADGroupOperation class] != Nil
				 && [MADOperationQueue class] != Nil
				 && [MADOperationConditionResult class] != Nil, "engine-link");
#endif
}

#pragma mark -
#pragma mark Report checks

static void MADProbeReportChecks(void) {
	// NSPredicate with MAD's exact predicate string.
	@try {
		MADProbeRow *withError = [[MADProbeRow alloc] init];
		withError.error = [NSError errorWithDomain:@"MADProbe" code:1 userInfo:nil];
		MADProbeRow *withoutError = [[MADProbeRow alloc] init];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"error != nil"];
		NSArray *filtered = [@[ withError, withoutError ] filteredArrayUsingPredicate:predicate];
		MADProbeReportItem("predicate", filtered.count == 1 && filtered[0] == withError,
						   [[NSString alloc] initWithFormat:@"filtered %lu of 2", (unsigned long)filtered.count]);
	} @catch (NSException *e) {
		MADProbeReportItem("predicate", NO, MADProbeExceptionDetail(e));
	}

	// Keyed archiving, secure coding -- the store's value-object path.
	@try {
		BOOL ok = NO;
		NSString *detail = nil;
		MADProbeBox *box = [[MADProbeBox alloc] initWithText:@"mad"];
		NSError *error = nil;
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:box requiringSecureCoding:YES error:&error];
		if (data == nil) {
			// GNUstep has no secure-coding support: the strict archive is nil
			// (and no error is reported).  The permissive path still proves
			// the coder machinery; the strict failure is the finding.
			NSData *permissive = [NSKeyedArchiver archivedDataWithRootObject:box requiringSecureCoding:NO error:NULL];
			id back = permissive ? [NSKeyedUnarchiver unarchiveObjectWithData:permissive] : nil;
			BOOL permissiveOk = [back isKindOfClass:[MADProbeBox class]] && [[back text] isEqualToString:@"mad"];
			detail = [[NSString alloc] initWithFormat:@"requiringSecureCoding:YES returns nil; requiringSecureCoding:NO round trip %@",
					  permissiveOk ? @"OK" : @"failed"];
		} else {
			id back = nil;
			Class unarchiver = [NSKeyedUnarchiver class];
			if ([unarchiver respondsToSelector:@selector(unarchivedObjectOfClass:fromData:error:)]) {
				MADProbeUnarchiveFn send = (MADProbeUnarchiveFn)objc_msgSend;
				back = send(unarchiver, @selector(unarchivedObjectOfClass:fromData:error:), [MADProbeBox class], data, &error);
				detail = @"unarchivedObjectOfClass:";
			} else if ([unarchiver respondsToSelector:@selector(unarchiveTopLevelObjectWithData:error:)]) {
				MADProbeUnarchiveLegacyFn send = (MADProbeUnarchiveLegacyFn)objc_msgSend;
				back = send(unarchiver, @selector(unarchiveTopLevelObjectWithData:error:), data, &error);
				detail = @"unarchiveTopLevelObjectWithData:";
			} else if ([unarchiver respondsToSelector:@selector(unarchiveObjectWithData:)]) {
				back = [NSKeyedUnarchiver unarchiveObjectWithData:data];
				detail = @"classic unarchiveObjectWithData:";
			} else {
				detail = @"no class-keyed unarchive entry point";
			}
			ok = [back isKindOfClass:[MADProbeBox class]] && [[back text] isEqualToString:@"mad"];
			if (!ok) {
				detail = error ? error.localizedDescription : detail;
			}
		}
		MADProbeReportItem("keyed-archiving", ok, detail);
	} @catch (NSException *e) {
		MADProbeReportItem("keyed-archiving", NO, MADProbeExceptionDetail(e));
	}

	// Binary property lists -- the MADDataTable cache path.
	@try {
		NSArray *rows = @[ @{ @"n": @1 }, @{ @"n": @2 } ];
		NSData *binary = [NSPropertyListSerialization dataWithPropertyList:rows format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
		id back = binary ? [NSPropertyListSerialization propertyListWithData:binary options:0 format:NULL error:NULL] : nil;
		MADProbeReportItem("plist-binary", [back isKindOfClass:[NSArray class]] && [back count] == 2, @"binary plist round trip failed");
	} @catch (NSException *e) {
		MADProbeReportItem("plist-binary", NO, MADProbeExceptionDetail(e));
	}

	// Directory enumeration by URL.  GNUstep's -enumeratorAtURL:... yields URLs with
	// the containing directory stripped -- file:///repo/.../London.dataset comes back
	// as file:///Contents.json -- which is why the CLI's member list uses
	// -subpathsAtPath: instead (measured 2026-10-16; BUGS.md).  The path-based
	// enumerators are correct, and this item checks that they still are.
	@try {
		NSString *directory = NSTemporaryDirectory();
		NSString *file = [directory stringByAppendingPathComponent: @"mad-probe-enumeration.txt"];
		[[NSFileManager defaultManager] createFileAtPath: file contents: [NSData data] attributes: nil];
		NSArray <NSString *> *subpaths = [[NSFileManager defaultManager] subpathsAtPath: directory];
		NSURL *byURL = nil;
		NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
											 enumeratorAtURL: [NSURL fileURLWithPath: directory]
											 includingPropertiesForKeys: nil options: 0 errorHandler: NULL];
		for (NSURL *url in enumerator) {
			if ([url.lastPathComponent isEqualToString: @"mad-probe-enumeration.txt"]) byURL = url;
		}
		BOOL pathFormOK = [subpaths containsObject: @"mad-probe-enumeration.txt"];
		BOOL urlFormWhole = byURL != nil && [byURL.path isEqualToString: file];
		MADProbeReportItem("directory-enumeration", pathFormOK,
						   @"-subpathsAtPath: did not list a file it had just written");
		MADProbeReportItem("directory-enumeration-url-form", urlFormWhole,
						   @"-enumeratorAtURL: yields URLs with the containing directory stripped;"
						   @" the CLI uses -subpathsAtPath: for its member list (BUGS.md)");
		[[NSFileManager defaultManager] removeItemAtPath: file error: NULL];
	} @catch (NSException *e) {
		MADProbeReportItem("directory-enumeration", NO, MADProbeExceptionDetail(e));
	}

	// App-group containers -- why MADURLFactory is not in the subset.
	MADProbeReportItem("app-groups",
					   [[NSFileManager defaultManager] respondsToSelector:@selector(containerURLForSecurityApplicationGroupIdentifier:)],
					   @"containerURLForSecurityApplicationGroupIdentifier: is absent");

	// The main queue drains under a plain executable.
	__block BOOL mainRan = NO;
	dispatch_async(dispatch_get_main_queue(), ^{
		mainRan = YES;
	});
	MADProbeReportItem("main-queue-drain", MADProbeWaitFor(^BOOL { return mainRan; }, 2.0),
					   @"main queue block never ran");

	// KVO dependent keys -- keyPathsForValuesAffecting...
	@try {
		MADProbeSubject *dependent = [[MADProbeSubject alloc] init];
		MADProbeObserver *dependentObserver = [[MADProbeObserver alloc] init];
		[dependent addObserver:dependentObserver forKeyPath:@"derived" options:0 context:NULL];
		dependent.value = 3;
		[dependent removeObserver:dependentObserver forKeyPath:@"derived"];
		MADProbeReportItem("kvo-dependent", dependentObserver.count >= 1, @"dependent key did not notify");
	} @catch (NSException *e) {
		MADProbeReportItem("kvo-dependent", NO, MADProbeExceptionDetail(e));
	}

	// NSOperation state-machine KVO -- the MADOperation contract.
	@try {
		MADProbeObserver *operationObserver = [[MADProbeObserver alloc] init];
		MADProbeAsyncOperation *operation = [[MADProbeAsyncOperation alloc] init];
		[operation addObserver:operationObserver forKeyPath:@"isFinished" options:0 context:NULL];
		NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
		[operationQueue addOperation:operation];
		BOOL finished = MADProbeWaitFor(^BOOL { return operation.isFinished; }, 3.0);
		if (finished) {
			[operation removeObserver:operationObserver forKeyPath:@"isFinished"];
		}
		MADProbeReportItem("nsoperation-kvo", finished && operationObserver.count >= 1 &&
						   operationQueue.operationCount <= 1,
						   @"asynchronous operation never finished on GNUstep");
	} @catch (NSException *e) {
		MADProbeReportItem("nsoperation-kvo", NO, MADProbeExceptionDetail(e));
	}

	// Sort descriptors -- the MADDataTable sort path.
	@try {
		NSArray *rows = @[ @{ @"name": @"b" }, @{ @"name": @"a" } ];
		NSArray *sorted = [rows sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
		MADProbeReportItem("sort-descriptor", sorted.count == 2 && [[sorted[0] objectForKey:@"name"] isEqualToString:@"a"], @"unexpected order");
	} @catch (NSException *e) {
		MADProbeReportItem("sort-descriptor", NO, MADProbeExceptionDetail(e));
	}

	// Streams -- the MADDataTable load path.
	@try {
		NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"madprobe-stream.txt"];
		[@"mad" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:path];
		[stream open];
		uint8_t buffer[8] = { 0 };
		NSInteger got = [stream read:buffer maxLength:sizeof(buffer)];
		[stream close];
		MADProbeReportItem("stream", got == 3, [[NSString alloc] initWithFormat:@"read %ld bytes of 3", (long)got]);
	} @catch (NSException *e) {
		MADProbeReportItem("stream", NO, MADProbeExceptionDetail(e));
	}

	// NSURLSession presence only; §5.3 says do not build on it.
	MADProbeReportItem("urlsession", NSClassFromString(@"NSURLSession") != Nil, @"class absent");
}

#pragma mark -
#pragma mark Main

int main(int argc, const char *argv[]) {
	(void)argc;
	(void)argv;
	@autoreleasepool {
		printf("ToolchainProbe: clang %d.%d, libobjc2, GNUstep Foundation\n",
			   __clang_major__, __clang_minor__);
		MADProbeCoreChecks();
		MADProbeReportChecks();
		printf("MADTEST ToolchainProbe tests=%u needs=%u failed=%u\n",
			   gCoreChecks, gReportNeeds, gCoreFailures);
	}
	if (gCoreFailures > 0) {
		printf("FAIL ToolchainProbe: %u core check(s) failed\n", gCoreFailures);
		return 1;
	}
	printf("OK ToolchainProbe: %u core checks, %u report item(s), %u need(s)\n",
		   gCoreChecks, gReportOk + gReportNeeds, gReportNeeds);
	return 0;
}
