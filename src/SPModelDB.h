//
//  SPModelDB.h
//  PersistedModel
//
//  Created by Metin Güler on 20/07/2017.
//  Copyright © 2017 Metin Güler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

@interface SPModelDB : NSObject
@property (nonatomic) FMDatabaseQueue *fmdbq;
@property (nonatomic) dispatch_queue_t serialq;

+ (NSString*)getSharedDBPath;
+ (SPModelDB*)shared;

@end


#ifndef dispatch_serialq_async_safe
#define dispatch_serialq_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(SPModelDB.shared.serialq)) == 0) {\
block();\
} else {\
dispatch_async(SPModelDB.shared.serialq, block);\
}
#endif

#ifndef dispatch_serialq_sync_safe
#define dispatch_serialq_sync_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(SPModelDB.shared.serialq)) == 0) {\
block();\
} else {\
dispatch_sync(SPModelDB.shared.serialq, block);\
}
#endif
