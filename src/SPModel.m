//
//  SPModelDB.m
//  PersistedModel
//
//  Created by Metin Güler on 20/07/2017.
//  Copyright © 2017 Metin Güler. All rights reserved.
//

#import "SPModel.h"
#import <objc/runtime.h>
#import "SPModelDB.h"
#import <sqlite3.h>

@implementation SPModel

static NSMutableSet *checkedSqlTables;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
            [self initializeSPModelWithDB:db];
        }];
    }
    return self;
}

- (instancetype)initWithDB:(FMDatabase*)db
{
    self = [super init];
    if (self) {
        [self initializeSPModelWithDB:db];
    }
    return self;
}

-(void)initializeSPModelWithDB:(FMDatabase*)db {
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
        [self createTableIfNeededWithSql:createSql withDB:db];
    });
}

- (BOOL)createTableIfNeededWithSql:(NSString*)createSql withDB:(FMDatabase*)db {
    __block BOOL methodResult = NO;
        
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
    
    return methodResult;
}

- (NSString*)getCrateTableSql {
    NSString *selfName = NSStringFromClass([self class]);
    NSArray *pro = [self propertyNames];
    
    NSMutableString *createSql = [NSMutableString stringWithFormat:@"create table %@ (", selfName];
    [createSql appendFormat:@"spid INTEGER PRIMARY KEY,"];
    
    for (NSString* title in pro) {
        NSString* type = [self getSqliteTypeFromPropertyName:title];
        if ([type hasPrefix:@"fk_"]) {
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
    __block BOOL result;
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        result = [self saveWithDB:db];
    }];
    
    return result;
}

- (BOOL)saveWithDB:(FMDatabase*)db {
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
                
                [(SPModel*)value saveWithDB:db];
                [values addObject:[NSNumber numberWithLongLong:[(SPModel*)value spid]]];
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
    result = [db executeUpdate:insertSql withArgumentsInArray:values];
    if (result == YES) {
        NSLog(@"%@ class object saved", NSStringFromClass([self class]));
    }
    
    self.spid = [db lastInsertRowId];
    
    return result;
}

+ (SPModel*)getObjectWithID:(NSInteger)modelid {
    __block SPModel *result;
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        result = [self getObjectWithID:modelid
                                withDB:db];
    }];
    return result;
}

+ (SPModel*)getObjectWithID:(NSInteger)modelid withDB:(FMDatabase*)db {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where spid = ?", NSStringFromClass([self class])];
    return [self getObjectWithSql:sql
                       withValues:@[[NSNumber numberWithInteger:modelid]]
                           withDB:db];
}

- (BOOL)update {
    __block BOOL result;
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        result = [self updateWithDB:db];
    }];
    
    return result;
}

- (BOOL)updateWithDB:(FMDatabase*)db {
    NSMutableString *updateSql = [NSMutableString stringWithFormat:@"update %@ set ", NSStringFromClass([self class])];
    NSMutableArray *values = [NSMutableArray new];
    NSArray *properities = [self propertyNames];
    
    //add properties to update sql
    for (NSString* title in properities) {
        
        id value = [self valueForKey:title];
        if (value) {
            
            if ([[value class] isSubclassOfClass:[SPModel class]]) {
                [(SPModel*)value updateWithDB:db];
            } else {
                [updateSql appendFormat:@"%@ = ?,", title];
                [values addObject:[self valueForKey:title]];
            }
            
        } else {
            // if value is null dont add to update sql
        }
    }
    
    // delete last comma
    [updateSql deleteCharactersInRange:NSMakeRange([updateSql length]-1, 1)];
    
    // append where with object id
    [updateSql appendString:@" where spid = ?"];
    [values addObject:[self valueForKey:@"spid"]];
    
    NSLog(@"update sql -> %@", updateSql);
    
    return [db executeUpdate:updateSql withArgumentsInArray:values];
}

- (BOOL)deleteObject {
    __block BOOL result;
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        result = [self deleteObjectWithDB:db];
    }];
    
    return result;
}

- (BOOL)deleteObjectWithDB:(FMDatabase*)db {
    NSMutableString *deleteSql = [NSMutableString stringWithFormat:@"delete from %@ where spid = ?", NSStringFromClass([self class])];
    return [db executeUpdate:deleteSql withArgumentsInArray:@[[self valueForKey:@"spid"]]];
}

+ (BOOL)bulkInsert:(NSArray<SPModel*>*)models {
    [SPModelDB.shared.fmdbq inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (SPModel *m in models) {
            [m saveWithDB:db];
        }
    }];
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
    
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:values];
        int columnCount = [rs columnCount];
        while ([rs next]) {
            __block id item = [[[self class] alloc] initWithDB:db];
            for (int i = 0; i < columnCount; i++) {
                NSString *columnName = [rs columnNameForIndex:i];
                
                if ([columnName hasPrefix:@"fk_"]) {
                    //parse column name to class and propertys name
                    NSString *tmp = [columnName stringByReplacingOccurrencesOfString:@"fk_"
                                                                          withString:@""];
                    NSArray *components = [tmp componentsSeparatedByString:@"_"];
                    NSString *classString = components[0];
                    NSString *propertyName = components[1];
                    
                    // create class from string
                    Class pclass = NSClassFromString(classString);
                    // get foreign key
                    NSNumber *_id = [rs objectForColumn:columnName];
                    SPModel *p = [pclass getObjectWithID:[_id integerValue] withDB:db];
                    
                    [item setValue:p forKey:propertyName];
                } else {
                    [item setValue:[rs objectForColumn:columnName] forKey:columnName];
                }
            }
            [array addObject:item];
        }
    }];
    return [array copy];
}

+ (SPModel*)getObjectWithSql:(NSString*)sql withValues:(NSArray*)values withDB:(FMDatabase*)db {
    FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:values];
    
    __block id item = [[[self class] alloc] initWithDB:db];
    if ([rs next]) {
        int columnCount = [rs columnCount];
        for (int i = 0; i < columnCount; i++) {
            NSString *columnName = [rs columnNameForIndex:i];
            
            if ([columnName hasPrefix:@"fk_"]) {
                //parse column name to class and propertys name
                NSString *tmp = [columnName stringByReplacingOccurrencesOfString:@"fk_"
                                                                         withString:@""];
                NSArray *components = [tmp componentsSeparatedByString:@"_"];
                NSString *classString = components[0];
                NSString *propertyName = components[1];
                
                // create class from string
                Class pclass = NSClassFromString(classString);
                // get foreign key
                NSNumber *_id = [rs objectForColumn:columnName];
                SPModel *p = [pclass getObjectWithID:[_id integerValue] withDB:db];
                
                [item setValue:p forKey:propertyName];
            } else {
                [item setValue:[rs objectForColumn:columnName] forKey:columnName];
            }
        }
    }
    return item;
}

#pragma mark - Obj-C Runtime

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
