//
//  SPModelDB.m
//  PersistedModel
//
//  Created by Metin Güler on 20/07/2017.
//  Copyright © 2017 Metin Güler. All rights reserved.
//

#import "SPModel.h"
#import <objc/runtime.h>
#import "FMDB.h"
#import "SPModelDB.h"
#import "SPModelTable.h"
#import "SPModelProperties.h"
#import <sqlite3.h>

@implementation SPModel

static NSMutableSet *checkedSqlTables;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            checkedSqlTables = [NSMutableSet new];
        });
        
        // prevent table check in every init, do it only once in a runtime
        // use serialq to prevent race condition
        dispatch_serialq_sync_safe(^{
            if ([checkedSqlTables containsObject:NSStringFromClass([self class])]) {
                return;
            }
            
            // create table if needed and log it
            NSString *createSql = [self getCrateTableSql];
            BOOL isTableCreated = [self createTableIfNeededWithSql:createSql];
            if (isTableCreated &&
                [self isKindOfClass:[SPModelTable class]] == NO &&
                [self isKindOfClass:[SPModelProperties class]] == NO) {
                
                dispatch_serialq_async_safe(^{
                    [self saveNewTableInfoWithSql:createSql];
                });
            }
            
            NSLog(@"%@ class object initialized", NSStringFromClass([self class]));
        });
        
        //TODO: Bir SPModel baska bir SPModelin property'si ise,
        //1.spmodel property'yi farket
        //2.sql tablosunda foreign key olarak kaydet. kolon adini daha sonradan okundugunda islenebilecek ve gidecegi tabloyu bulduracak sekilde ayarla
        //3. foreign key'in karsiligini olustur. Transaction kullan
    }
    return self;
}

- (void)saveNewTableInfoWithSql:(NSString*)createSql {
    SPModelTable *newTable = [SPModelTable new];
    newTable.name = NSStringFromClass([self class]);
    newTable.createSql = createSql;
    [newTable save];
    
    NSArray *pro = [self propertyNames];
    for (NSString* title in pro) {
        NSString* type = [self getSqliteTypeFromPropertyName:title];
        SPModelProperties *mp = [SPModelProperties new];
        mp.fk_spmodeltable = newTable.spid;
        mp.name = title;
        mp.type = type;
        [mp save];
    }
}

- (BOOL)createTableIfNeededWithSql:(NSString*)createSql {
    __block BOOL methodResult;
    
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        
        NSString *sql = [NSString stringWithFormat:@"select * from %@ limit 1", NSStringFromClass([self class])];
        FMResultSet *result = [db executeQuery:sql];
        
        // set checked
        [checkedSqlTables addObject:NSStringFromClass([self class])];
        
        // if there is not table, create one
        if (result == nil) {
            if ([db executeUpdate:createSql] == YES) {
                methodResult = YES;
                NSLog(@"√ %@ table created", NSStringFromClass([self class]));
            } else {
                NSLog(@"X %@ table could not created", NSStringFromClass([self class]));
            }
        }
        
        [result close];
    }];
    
    return methodResult;
}

- (NSString*)getCrateTableSql {
    NSString *selfName = NSStringFromClass([self class]);
    NSArray *pro = [self propertyNames];
    
    NSMutableString *createSql = [NSMutableString stringWithFormat:@"create table %@ (", selfName];
    [createSql appendFormat:@"spid INTEGER PRIMARY KEY,"];
    
    for (NSString* title in pro) {
        NSString* type = [self getSqliteTypeFromPropertyName:title];
        //TODO: change to starts with
        if ([type containsString:@"fk_"]) {
            [createSql appendFormat:@" %@ %@,", type, @"INTEGER"];
        } else {
            [createSql appendFormat:@" %@ %@,", title, type];
        }
    }
    
    // delete last comma
    [createSql deleteCharactersInRange:NSMakeRange([createSql length]-1, 1)];
    [createSql appendString:@");"];
    
    return createSql;
}

- (NSString*)getSqliteTypeFromPropertyName:(NSString*)name {
    NSString *type = [NSString stringWithUTF8String:[self typeOfPropertyNamed:name]];
    
    type = [type stringByReplacingOccurrencesOfString:@"T" withString:@""];
    type = [type stringByReplacingOccurrencesOfString:@"@" withString:@""];
    type = [type stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    if ([type length] == 1) {
        char typeChar = [type UTF8String][0];
        switch (typeChar) {
            case 'd':
            case 'f':
                return @"REAL";
                break;
                
            case 'i':
            case 'q':
            case 'u':
            case 'U':
                return @"INTEGER";
                break;
                
            default:
                return @"INTEGER";
                break;
        }
    }
    
    if ([type containsString:@"NSString"]) {
        return @"TEXT";
    } else  {
        Class c = NSClassFromString(type);
        if ([c isSubclassOfClass:[SPModel class]]) {
            // Foreign key formar is fk_<ClassName>_<PropertyName>
            return [NSString stringWithFormat:@"fk_%@_%@", type, name];
        }
    }
    return @"TEXT";
}


#pragma mark - CRUD

- (BOOL)save {
    NSMutableString *insertSql = [NSMutableString stringWithFormat:@"insert into %@(", NSStringFromClass([self class])];
    NSArray *properties = [self propertyNames];
    
    NSMutableString *valuesString = [NSMutableString new];
    NSMutableArray *values = [NSMutableArray new];
    
    for (NSString* title in properties) {
        [valuesString appendString:@"?,"];
        
        id value = [self valueForKey:title];
        if (value) {
            if ([[value class] isSubclassOfClass:[SPModel class]]) {
                [insertSql appendFormat:@"fk_%@_%@,", NSStringFromClass([value class]), title];
                
                [(SPModel*)value save];
                [values addObject:[NSNumber numberWithInteger:[(SPModel*)value spid]]];
            } else {
                [insertSql appendFormat:@"%@,", title];
                [values addObject:[self valueForKey:title]];
            }
        } else {
            [values addObject:@"NULL"];
        }
    }
    
    // delete last comma
    [insertSql deleteCharactersInRange:NSMakeRange([insertSql length]-1, 1)];
    [valuesString deleteCharactersInRange:NSMakeRange([valuesString length] -1, 1)];
    
    [insertSql appendFormat:@") values(%@);", valuesString];
    
//    NSLog(@"insert sql %@", insertSql);
    
    __block BOOL result;
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdate:insertSql withArgumentsInArray:values];
        if (result == YES) {
            NSLog(@"%@ class object saved", NSStringFromClass([self class]));
        }
        
        self.spid = [db lastInsertRowId];
    }];
    
    return result;
}

+ (SPModel*)getObjectWithID:(NSInteger)modelid {
    return [self getObjectWithID:modelid
                          withDB:nil];
}

+ (SPModel*)getObjectWithID:(NSInteger)modelid withDB:(FMDatabase*)db {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where spid = %li", NSStringFromClass([self class]), modelid];
    return [self getObjectWithSql:sql
                       withValues:@[[NSNumber numberWithInteger:modelid]]
                           withDB:db];
}

- (BOOL)update {
    NSMutableString *updateSql = [NSMutableString stringWithFormat:@"update %@ set ", NSStringFromClass([self class])];
    NSArray *properities = [self propertyNames];
    
    NSMutableArray *values = [NSMutableArray new];
    for (NSString* title in properities) {
        [updateSql appendFormat:@"%@ = ?,", title];
        
        id value = [self valueForKey:title];
        if (value) {
            [values addObject:[self valueForKey:title]];
        } else {
            [values addObject:@"NULL"];
        }
    }
    
    // delete last comma
    [updateSql deleteCharactersInRange:NSMakeRange([updateSql length]-1, 1)];
    
    [updateSql appendString:@" where spid = ?"];
    [values addObject:[self valueForKey:@"spid"]];
    
    NSLog(@"update sql -> %@", updateSql);
    
    __block BOOL result;
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdate:updateSql withArgumentsInArray:values];
    }];
    
    return result;
}

- (BOOL)deleteObject {
    NSMutableString *deleteSql = [NSMutableString stringWithFormat:@"delete from %@ where spid = ?", NSStringFromClass([self class])];
    
    __block BOOL result;
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdate:deleteSql withArgumentsInArray:@[[self valueForKey:@"spid"]]];
    }];
    
    return result;
    
    return YES;
}

#pragma mark - Query methods

+ (NSArray*)getAll {
    NSString *sql = [NSString stringWithFormat:@"select * from %@", NSStringFromClass([self class])];
    return [self getObjectsWithSql:sql
                        withValues:@[]];
}

+ (NSArray*)getAllWithOffset:(int)offset withLimit:(int)limit {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ limit ?,?", NSStringFromClass([self class])];
    return [self getObjectsWithSql:sql
                        withValues:@[[NSNumber numberWithInt:offset],
                                     [NSNumber numberWithInt:limit]]];
}

+ (NSArray*)getAllWithQuery:(NSString*)whereSql values:(NSArray*)values {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@", NSStringFromClass([self class]), whereSql];
    return [self getObjectsWithSql:sql
                        withValues:values];
}

+ (NSArray*)getAllWithQuery:(NSString*)query values:(NSArray*)values withOffset:(int)offset withLimit:(int)limit {
    values = [NSArray arrayWithObjects:[NSNumber numberWithInt:offset], [NSNumber numberWithInt:limit], nil];
    
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ limit ?,?", NSStringFromClass([self class]), query];
    return [self getObjectsWithSql:sql
                        withValues:values];
}

+ (NSArray*)getObjectsWithSql:(NSString*)sql withValues:(NSArray*)values {
    NSMutableArray *array = [NSMutableArray new];
    
    //TODO: first init calls create table sql, if this called indside fmdbqueue, queue will be deadlocked
    //this line is workround. FMDB instance should send to init for safety
    __block id item = [[[self class] alloc] init];
    
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:values];
        NSMutableDictionary *columnMap = [rs columnNameToIndexMap];
        while ([rs next]) {
            item = [[[self class] alloc] init];
            [columnMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber *_Nonnull obj, BOOL * _Nonnull stop) {
                //TODO: change to starts with
                if ([key containsString:@"fk_"]) {
                    // columnNameForIndex called because FMResultSet columnNameToIndexMap method lowercases all names
                    NSString *orjColumnName = [rs columnNameForIndex:[obj intValue]];
                    NSString *tmp = [orjColumnName stringByReplacingOccurrencesOfString:@"fk_"
                                                                           withString:@""];
                    NSArray *components = [tmp componentsSeparatedByString:@"_"];
                    NSString *classString = components[0];
                    NSString *propertyName = components[1];
                    
                    Class pclass = NSClassFromString(classString);
                    
                    NSNumber *_id = [rs objectForColumn:key];
                    SPModel *p = [pclass getObjectWithID:[_id integerValue] withDB:db];
                    
                    [item setValue:p forKey:propertyName];
                } else {
                    [item setValue:[rs objectForColumn:key] forKey:key];
                }
            }];
            [array addObject:item];
        }
    }];
    return [array copy];
}

+ (SPModel*)getObjectWithSql:(NSString*)sql withValues:(NSArray*)values withDB:(FMDatabase*)db {
    
    //TODO: first init calls create table sql, if this called indside fmdbqueue, queue will be deadlocked
    //this line is workround. FMDB instance should send to init for safety
    __block id item = [[[self class] alloc] init];
    
    [self startFMDBQueueSafelyWithDB:db inDatabase:^(FMDatabase *db) {
    
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:values];
        NSMutableDictionary *columnMap = [rs columnNameToIndexMap];
        while ([rs next]) {
            [columnMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber *_Nonnull obj, BOOL * _Nonnull stop) {
                //TODO: change to starts with
                if ([key containsString:@"fk_"]) {
                    // columnNameForIndex called because FMResultSet columnNameToIndexMap method lowercases all names
                    NSString *orjColumnName = [rs columnNameForIndex:[obj intValue]];
                    NSString *tmp = [orjColumnName stringByReplacingOccurrencesOfString:@"fk_"
                                                                             withString:@""];
                    NSArray *components = [tmp componentsSeparatedByString:@"_"];
                    NSString *classString = components[0];
                    NSString *propertyName = components[1];
                    
                    Class pclass = NSClassFromString(classString);
                    
                    NSNumber *_id = [rs objectForColumn:key];
                    SPModel *p = [pclass getObjectWithID:[_id integerValue] withDB:db];
                    
                    [item setValue:p forKey:propertyName];
                } else {
                    [item setValue:[rs objectForColumn:key] forKey:key];
                }
            }];
        }
    }];
    return item;
}

+ (void)startFMDBQueueSafelyWithDB:(FMDatabase*)db
                        inDatabase:(void (^)(FMDatabase *db))block {
    if (db == nil) {
        [SPModelDB.shared.fmdbq inDatabase:block];
    } else {
        block(db);
    }
}

+ (void)startFMDBQueueSafelyWithDB:(FMDatabase*)db
                          rollback:(BOOL*)rollback
                     inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
    if (db == nil) {
        [SPModelDB.shared.fmdbq inTransaction:block];
    } else {
        block(db, rollback);
    }
}

#pragma mark - Obj Runtime

- (NSArray *) propertyNames
{
    return ( [[self class] propertyNames] );
}

- (const char *) typeOfPropertyNamed: (NSString *) name
{
    return ( [[self class] typeOfPropertyNamed: name] );
}

+ (NSArray *) propertyNames
{
    unsigned int i, count = 0;
    objc_property_t * properties = class_copyPropertyList( self, &count );
    
    if ( count == 0 )
    {
        free( properties );
        return ( nil );
    }
    
    NSMutableArray * list = [NSMutableArray array];
    
    for ( i = 0; i < count; i++ )
        [list addObject: [NSString stringWithUTF8String: property_getName(properties[i])]];
    
    return ( [list copy] );
}

+ (const char *) typeOfPropertyNamed: (NSString *) name
{
    objc_property_t property = class_getProperty( self, [name UTF8String] );
    if ( property == NULL )
        return ( NULL );
    
    return ( property_getTypeString(property) );
}

const char * property_getTypeString( objc_property_t property )
{
    const char * attrs = property_getAttributes( property );
    if ( attrs == NULL )
        return ( NULL );
    
    static char buffer[256];
    const char * e = strchr( attrs, ',' );
    if ( e == NULL )
        return ( NULL );
    
    int len = (int)(e - attrs);
    memcpy( buffer, attrs, len );
    buffer[len] = '\0';
    
    return ( buffer );
}

@end
