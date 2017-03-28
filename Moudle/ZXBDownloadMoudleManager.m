//
//  ZXBDownloadMoudleManager.m
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/2/27.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import "ZXBDownloadMoudleManager.h"
#import "ZXBDownloadMoudle.h"

static NSString *const kZXBDownloadMoudlePlist = @"zxb_download_moudle";

@interface ZXBDownloadMoudleManager()
@property (nonatomic,copy)      NSMutableDictionary<NSString*,ZXBDownloadMoudle*>     *moudleDic;
@property (nonatomic,strong)    NSLock                                                *lock;
@end

@implementation ZXBDownloadMoudleManager

+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    static id sharedManager = nil;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    
    return sharedManager;
}

- (instancetype) init{
    self = [super init];
    if (self) {
        _moudleDic = [[NSMutableDictionary alloc] initWithCapacity:3];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:kZXBDownloadMoudlePlist ofType:@"plist"];
        NSArray *moudleArray = [[NSArray alloc] initWithContentsOfFile:path];
        [moudleArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *data = obj;
            NSString *moudleId = data[@"moudleId"];
            NSAssert(moudleId, @"moudleId in plist is nil");
            
            ZXBDownloadMoudle *moudle = [[ZXBDownloadMoudle alloc] initWithMoudleId:data[@"moudleId"]];
            moudle.targetPath = data[@"targetPath"];
            moudle.tmpPath = data[@"tmpPath"];
            
            [self registerMoudle:moudle];
        }];
        
        _lock = [[NSLock alloc] init];
        _lock.name = @"ZXBDownloadMoudleManagerLock";
    }
    
    return self;
}

- (void) registerMoudle:(ZXBDownloadMoudle*) moudle{
    [_lock lock];
    NSString *registerKey = moudle.moudleId;
    
    if (!registerKey || _moudleDic[registerKey]) {
        return;
    }
    
    _moudleDic[registerKey] = moudle;
    [_lock unlock];
}

- (void) removeMoudle:(ZXBDownloadMoudle*) moudle{
    [_lock lock];
    NSString *registerKey = moudle.moudleId;
    
    if (!registerKey || !_moudleDic[registerKey]) {
        return;
    }
    
    [_moudleDic removeObjectForKey:registerKey];
    [_lock unlock];
}

- (ZXBDownloadMoudle*) moudleWithId:(NSString*) moudleId{
    if(!moudleId){
        return nil;
    }
    
    [_lock lock];
    ZXBDownloadMoudle *moudle =  _moudleDic[moudleId];
    [_lock unlock];
    
    return moudle;
}

@end
