//
//  SPModelDB.h
//  PersistedModel
//
//  Created by Metin Güler on 20/07/2017.
//  Copyright © 2017 Metin Güler. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPModel : NSObject

@property (nonatomic) NSInteger spid;

- (BOOL)save;
+ (SPModel*)getObjectWithID:(NSInteger)modelid;
- (BOOL)update;
- (BOOL)deleteObject;
+ (NSArray*)getAll;
+ (NSArray*)getAllWithOffset:(int)offset withLimit:(int)limit;
+ (NSArray*)getAllWithQuery:(NSString*)whereSql values:(NSArray*)values;
+ (NSArray*)getAllWithQuery:(NSString*)query values:(NSArray*)values withOffset:(int)offset withLimit:(int)limit;

@end
