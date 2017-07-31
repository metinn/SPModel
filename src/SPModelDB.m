//
//  SPModelDB.m
//  PersistedModel
//
//  Created by Metin Güler on 20/07/2017.
//  Copyright © 2017 Metin Güler. All rights reserved.
//

#import "SPModelDB.h"
#import <sqlite3.h>

@implementation SPModelDB

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *writableDBPath = [SPModelDB getSharedDBPath];
        NSLog(@"Spmodel db Path %@", writableDBPath);
        
        self.serialq = dispatch_queue_create([@"com.spmodel.db" UTF8String], DISPATCH_QUEUE_SERIAL);
        self.fmdbq = [FMDatabaseQueue databaseQueueWithPath:writableDBPath
                                                      flags:SQLITE_OPEN_READWRITE |
                                                            SQLITE_OPEN_CREATE |
                                                            SQLITE_OPEN_FILEPROTECTION_NONE];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:writableDBPath] == NO) {
            // First execution
        }
    }
    return self;
}

+ (NSString*)getSharedDBPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = paths[0];
    return [docPath stringByAppendingPathComponent:@"spmodel.db"];
}

#pragma mark - Singleton

static SPModelDB *shared;

+ (SPModelDB*)shared {
    static dispatch_once_t onceToken;
    // TODO: change dispatch once with barrier
    dispatch_once(&onceToken, ^{
        shared = [[SPModelDB alloc] init];
    });
    return shared;
}

@end
