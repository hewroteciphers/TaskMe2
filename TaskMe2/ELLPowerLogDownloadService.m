//
//  ELLPowerLogDownloadService.m
//  iOS Diagnostics
//
//  Created by Christopher Anderson on 06/11/2014.
//  Copyright (c) 2014 Electric Labs. All rights reserved.
//


#import "ELLPowerLogDownloadService.h"
#import "ELLMBSDevice.h"
#import "GZIP.h"

//#import <DropboxSDK/DropboxSDK.h>



#if !TARGET_IPHONE_SIMULATOR
static const NSUInteger kELLMaxNumberOfRetries = 1;
#endif

@interface ELLPowerLogDownloadService()
@property (nonatomic, strong) dispatch_source_t	src;
@property (nonatomic, strong) NSArray *sqlLogFiles;
@property (nonatomic, strong) NSArray *compressSqlFiles;
@property (nonatomic, strong) id mbsDevice;
@property (nonatomic, assign) NSUInteger retryCount;

@end

@implementation ELLPowerLogDownloadService

- (void)startPowerLogDownload {
    self.retryCount = 0;
    
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _prepareLogDirectory];
        [self _loadPowerLogs];
   });
}


- (void)_loadPowerLogs {

#if TARGET_IPHONE_SIMULATOR
    NSString *pathToTestData = [[NSBundle mainBundle] pathForResource:@"TestData.PLSQL" ofType:@"gz"];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *pathToTestDataInTemp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TestData.PLSQL.gz"];
    [fileManager copyItemAtPath:pathToTestData toPath:pathToTestDataInTemp error:nil];
    NSString *pathToUncompressedTestData = [self _extractGZIPFile:pathToTestDataInTemp];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(powerLogDownloadService:didFinishWithSQLLogFiles:compressedSQLFiles:)]) {
           [self.delegate powerLogDownloadService:self didFinishWithSQLLogFiles:@[pathToUncompressedTestData] compressedSQLFiles:@[pathToTestDataInTemp]];
        }
    });
#else
    NSBundle *b = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/iOSDiagnosticsSupport.framework"];
    BOOL hasLoaded = [b load];
    
    BOOL success = NO;
    
    if (hasLoaded) {
        Class MBSDevice = NSClassFromString(@"MBSDevice");
        
        self.mbsDevice = [[MBSDevice alloc] init];;
        if (self.mbsDevice) {
            NSLog(@"mbsDevice copying PowerLogs to %@", [self _logPath]);
            

            [self.mbsDevice copyPowerLogsToDir:[self _logPath]];
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSDirectoryEnumerator *dir = [fileManager enumeratorAtPath:[self _logPath]];
            NSArray *allFiles = [dir allObjects];

            NSLog(@"# of powerLogs %lU", (unsigned long)allFiles.count);
            if (allFiles.count) {
                success = YES;
                NSMutableArray *sqlLogFiles = [NSMutableArray array];
                NSMutableArray *compressedSqlFiles = [NSMutableArray array];
                
                NSLog(@"uncompressing...");
                
                
                for (NSString *theURL in allFiles) {
                    NSString *compressedSqlFile = [[self _logPath] stringByAppendingPathComponent:theURL];
//                    NSString *powerLogSQLFile = [self _extractGZIPFile:compressedSqlFile];
//                    if (powerLogSQLFile) {
//                        [sqlLogFiles addObject:powerLogSQLFile];
                        [compressedSqlFiles addObject:compressedSqlFile];
//                    }
                    
                }
//                self.sqlLogFiles = sqlLogFiles;
                self.compressSqlFiles = compressedSqlFiles;
                NSLog(@"gunzip done.");
                
            }
        }
    }
    
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(powerLogDownloadService:didFinishWithSQLLogFiles:compressedSQLFiles:)]) {
                [self.delegate powerLogDownloadService:self didFinishWithSQLLogFiles:self.sqlLogFiles compressedSQLFiles:self.compressSqlFiles];
            }
        });
    } else {
        if (self.retryCount++ >= kELLMaxNumberOfRetries) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(powerLogDownloadService:didFailWithError:)]) {
                    [self.delegate powerLogDownloadService:self didFailWithError:[NSError errorWithDomain:@"com.weetopia.iOSDiagnostics" code:500 userInfo:nil]];
                }
            });
        } else {
//            [self _loadPowerLogs];      // Try a 2nd time
        }
        
    }
#endif
}


- (NSString *)_extractGZIPFile:(NSString *)filePath {
    if ([filePath rangeOfString:@"gz"].location == NSNotFound) {
        return nil;
    }

    NSString *powerLogPath = [filePath stringByDeletingPathExtension];
    NSData *dataForLogFile = [NSData dataWithContentsOfFile:filePath];
    NSData *ungzipedData  = [dataForLogFile gunzippedData];
    [ungzipedData writeToFile:powerLogPath atomically:YES];
    return powerLogPath;
}


- (void)_prepareLogDirectory {
    NSString *logPath = [self _logPath];
    NSFileManager *fileManager = [NSFileManager new];
    
    NSError *error;
    [fileManager removeItemAtPath:logPath error:&error];
    [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:NULL error:&error];
}

- (NSString*)_logPath {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"powerLogs"];
}


@end
