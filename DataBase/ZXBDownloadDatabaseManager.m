//
//  ZXBDownloadDataBaseManager.m
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/3/10.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import "ZXBDownloadDatabaseManager.h"
#import "ZXBDownloadItem.h"
#import "FMDB.h"

static NSString *const kZXBDbFileName = @"zxb.db";
static NSString *const kZXBDownloadTableName = @"zxb_resource_download_table";
//sqlite 复合键
//table : id(userId+itemId+moudleId) itemId userId fileName url moudleId timeStamp state tmpPath targetPath progress
static NSString *const kTableKey        = @"id";
static NSString *const kTableItemId     = @"itemId";
static NSString *const kTableUserId     = @"userId";
static NSString *const kTableFileName   = @"fileName";
static NSString *const kTableUrl        = @"url";
static NSString *const kTableMoudleId   = @"moudleId";
static NSString *const kTableTimeStamp  = @"timeStamp";
static NSString *const kTableState      = @"state";
static NSString *const kTmpPath         = @"tmpPath";
static NSString *const kTargetPath      = @"targetPath";
static NSString *const kProgress        = @"progress";

@interface ZXBDownloadDatabaseManager()
@property (nonatomic,strong) FMDatabaseQueue    *dbQueue;
@property (nonatomic,strong) NSRecursiveLock    *databaseLock;
@end

@implementation ZXBDownloadDatabaseManager

- (instancetype) init{
    self = [super init];
    if (self) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[[self class] pathForZXBDataBase]];
        _databaseLock = [[NSRecursiveLock alloc] init];
        _databaseLock.name = @"ZXBDownloadDatabaseLock";
        [self createTableIfNeeded];
    }
    
    return self;
}

- (void) createTableIfNeeded{
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ('%@' TEXT PRIMARY KEY, '%@' TEXT, '%@' TEXT,'%@' TEXT,'%@' TEXT, '%@' TEXT,'%@' DOUBLE, '%@' INTEGER,'%@' TEXT, '%@' TEXT,'%@' DOUBLE)",kZXBDownloadTableName,kTableKey,kTableItemId,kTableUserId,kTableFileName,kTableUrl,kTableMoudleId,kTableTimeStamp,kTableState,kTmpPath,kTargetPath,kProgress];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        BOOL isSuccess = [db executeStatements:sql];
        if (!isSuccess) {
            NSLog(@"数据库 建立失败");
        }
    }];
}

- (void) deleteItem:(ZXBDownloadItem*) item{
    [_databaseLock lock];
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@='%@'",kZXBDownloadTableName,kTableKey,[item resourceId]];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        BOOL isSuccess = [db executeUpdate:sql];
        if (!isSuccess) {
            NSLog(@"数据库 删除失败");
        }
    }];
    
    [_databaseLock unlock];
}

- (void) addItem:(ZXBDownloadItem*) item{
    [_databaseLock lock];
    
    NSDate *currentDtae = [NSDate date];
    currentDtae = [self fixDateToLocale:currentDtae];
    
    NSString *sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@, %@, %@, %@, %@ ,%@, %@ ,%@,%@, %@ ,%@) VALUES ('%@','%@','%@','%@','%@','%@',%@,%@,'%@','%@',%@);",kZXBDownloadTableName,kTableKey,kTableItemId,kTableUserId,kTableFileName,kTableUrl,kTableMoudleId,kTableTimeStamp,kTableState,kTmpPath,kTargetPath,kProgress,[item resourceId],item.itemId,[item userId],item.fileName,item.downloadUrl,item.moudleId,@(currentDtae.timeIntervalSince1970),@(item.state),item.tmpFilePath,item.targetPath,@(item.downloadProgress)];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        BOOL isSuccess = [db executeUpdate:sql];
        if (!isSuccess) {
            NSLog(@"数据库 插入失败");
        }
    }];
    
    [_databaseLock unlock];
}

- (NSArray*) queryAllWithMoudleId:(NSString*) moudleId userId:(NSString*) userId{
    [_databaseLock lock];
    
    NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@='%@' AND %@='%@'",kZXBDownloadTableName, kTableUserId, userId, kTableMoudleId, moudleId];
    
    NSMutableArray *array = [NSMutableArray new];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql];
        
        while ([rs next]) {
            NSString *itemId = [rs stringForColumn:kTableItemId];
            NSString *url = [rs stringForColumn:kTableUrl];
            NSString *tmpPath = [rs stringForColumn:kTmpPath];
            NSString *targetPath = [rs stringForColumn:kTargetPath];
            NSString *fileName = [rs stringForColumn:kTableFileName];
            
            ZXBDownloadItem *item = [[ZXBDownloadItem alloc] initWithItemId:itemId moudleId:moudleId url:url];
            item.state = [rs intForColumn:kTableState];
            item.fileName = [self correctName:fileName];
            item.downloadProgress = [rs doubleForColumn:kProgress];
            item.tmpFilePath = [self correctName:tmpPath];
            item.targetPath = [self correctName:targetPath];
            item.timeStamp = [rs doubleForColumn:kTableTimeStamp];
            
            [array addObject:item];
        }
    }];
    
    [_databaseLock unlock];
    
    return array.copy;
}

-(NSString*) correctName:(NSString*) rawName{
    if (!rawName || rawName.length == 0 || [rawName isEqualToString:@"(null)"]) {
        return nil;
    }else{
        return rawName;
    }
}

#pragma mark -
//知学宝业务的数据库路径
+(NSString*) pathForZXBDataBase{
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES).firstObject;
    NSString *dataBaseName = [documents stringByAppendingPathComponent:kZXBDbFileName];
    return dataBaseName;
}

-(NSDate*) fixDateToLocale:(NSDate*) originDate{
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: originDate];
    NSDate *localeDate = [originDate  dateByAddingTimeInterval: interval];
    
    return localeDate;
}

@end
