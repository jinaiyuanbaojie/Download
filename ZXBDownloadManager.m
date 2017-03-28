//
//  ZXBTestDownloadManager.m
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/3/7.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//


#import "ZXBDownloadItem.h"
#import "ZXBDownloadManager.h"
#import "ZXBDownloadFileUtils.h"
#import "ZXBDownloadMoudle.h"
#import "ZXBDownloadMoudleManager.h"
#import "ZXBResourceDownloader.h"
#import "ZXBDownloadError.h"
#import "ZXBDownloadDatabaseManager.h"

static NSInteger const kConcurrentDownloadNumber = 6;
NSString *const ZXBDownloadErrorDomain = @"com.iflytek.zxb.download";

@interface ZXBDownloadManager()<NSURLSessionDataDelegate>
@property (nonatomic,strong) NSURLSession                                                   *urlSessionManager;
@property (nonatomic,strong) NSOperationQueue                                               *operationQueue;
@property (nonatomic,strong) ZXBDownloadDatabaseManager                                     *databaseManager;

@property (nonatomic,copy)   NSMutableDictionary<NSString*,ZXBResourceDownloader*>          *downloadTaskDic; //key itemId. value Downloader;控制下载 暂停
@property (nonatomic,copy)   NSMutableDictionary<NSNumber*,ZXBResourceDownloader*>          *downloadItemDelegateDic; //key taskId.value Downloader;控制下载回调分发
@property (nonatomic,copy)   NSMutableDictionary<NSString*,id<ZXBDownloadSessionDeleagte>>  *downloadMoudleDelegateDic; //给downloader 具体的业务回调赋值。

@property (nonatomic,strong) NSRecursiveLock                                                *dicLock;
@end

@implementation ZXBDownloadManager

+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    static id sharedManager = nil;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    
    return sharedManager;
}


-(instancetype) init{
    self = [super init];
    if (self) {
        //backgroundSessionConfigurationWithIdentifier 支持后台下载,但是需要iOS8以上
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.name = @"zxb_download_opration_queue";
        _operationQueue.maxConcurrentOperationCount = 1;
        _urlSessionManager = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_operationQueue];
        
        _databaseManager = [[ZXBDownloadDatabaseManager alloc] init];
        
        _downloadTaskDic = [[NSMutableDictionary alloc] initWithCapacity:kConcurrentDownloadNumber];
        _downloadItemDelegateDic = [[NSMutableDictionary alloc] initWithCapacity:kConcurrentDownloadNumber];
        _downloadMoudleDelegateDic = [[NSMutableDictionary alloc] init];
                
        _dicLock = [[NSRecursiveLock alloc] init];
        _dicLock.name = @"ZXBDownloadMangerDicLock";
    }
    
    return self;
}


-(BOOL) canAcceptNewTask{
    [_dicLock lock];
    NSInteger currentNum = _downloadTaskDic.count;
    BOOL ret = currentNum < kConcurrentDownloadNumber;
    [_dicLock unlock];
    
    return ret;
}

#pragma mark -

-(void) startWithItem:(ZXBDownloadItem*)item{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_dicLock lock];
        
        NSError *error = [self checkExceptionBeforeDownload:item];
        
        id<ZXBDownloadSessionDeleagte> delegate = _downloadMoudleDelegateDic[item.moudleId];
        
        if (error) {
            [delegate notifyDownloadResultWithError:error item:item];
            return;
        }
        
        ZXBResourceDownloader *downloader = [[ZXBResourceDownloader alloc] initWithDownloadItem:item downloadDelegate:delegate];
        [downloader startUnderSession:self.urlSessionManager];
        
        _downloadTaskDic[[item resourceId]] = downloader;
        _downloadItemDelegateDic[[downloader taskIdentifier]] = downloader;
        item.state = ZXBDownloadStateDownloading;
        
        [_databaseManager addItem:item];
        
        [_dicLock unlock];
    });
}

- (void) resumeWithItem:(ZXBDownloadItem*) item{
    if (!item.itemId || ![self canAcceptNewTask]) {
        return;
    }
    
    [self startWithItem:item];
}

- (void) pauseWithItem:(ZXBDownloadItem*) item{
    [self cancelWithItem:item refreshState:ZXBDownloadStatePause];
}

- (void) cancelWithItem:(ZXBDownloadItem*) item{
    [self cancelWithItem:item refreshState:ZXBDownloadStateCancel];
}

//暂停或者取消导致的cancel
- (void) cancelWithItem:(ZXBDownloadItem*) item refreshState:(ZXBDownloadState) state{
    if (!item.itemId) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_dicLock lock];
        ZXBResourceDownloader *downloader = _downloadTaskDic[[item resourceId]];
        
        //任务已经下载完成，downloader=nil,取消一个已经完成的任务没有意义
        if (downloader) {
            item.state = state;
            //cancel后会走下载完毕的回调，数据处理都放在回调中做
            [downloader cancel];
        }
        
        [_dicLock unlock];
    });
}

#pragma mark -

- (void) registerDownloadDelegate:(id<ZXBDownloadSessionDeleagte>) delegate forMoudle:(NSString*) moudleId{
    if (!moudleId || !delegate) {
        return;
    }
    
    [_dicLock lock];
    
    _downloadMoudleDelegateDic[moudleId] = delegate;
    [_downloadTaskDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ZXBResourceDownloader * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([[obj matchDownloadItem].moudleId isEqualToString:moudleId]) {
            [obj configNewDelegate:delegate];
        }
    }];
    
    [_dicLock unlock];
}

- (void) removeDownloadDelegateForMoudle:(NSString*) moudleId{
    if (!moudleId) {
        return;
    }
    
    [_dicLock lock];
    
    [_downloadMoudleDelegateDic removeObjectForKey:moudleId];
    [_downloadTaskDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ZXBResourceDownloader * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([[obj matchDownloadItem].moudleId isEqualToString:moudleId]) {
            [obj removeDelegate];
        }
    }];
    
    [_dicLock unlock];
}

- (NSInteger) currentDownloadNumUnderMoudle:(NSString*) moudleId{
    __block NSInteger ret = 0;

    [_dicLock lock];
    
    if (moudleId) {
        [_downloadTaskDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ZXBResourceDownloader * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([[obj matchDownloadItem].moudleId isEqualToString:moudleId]) {
                ret++;
            }
        }];
    }else{
        ret = _downloadTaskDic.count;
    }

    [_dicLock unlock];
    return ret;
}

- (NSArray<ZXBDownloadItem*>*) unCompleteItemsUnderMoudle:(NSString*) moudleId{
    [_dicLock lock];
    
    NSArray<ZXBDownloadItem*>* retArray = nil;
    retArray = [_databaseManager queryAllWithMoudleId:moudleId userId:@""];
    
    [_dicLock unlock];
    
    return retArray;
}

#pragma mark - session_delegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{    
    [[self delegateOnDataTask:dataTask] URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [[self delegateOnDataTask:dataTask] URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    ZXBResourceDownloader *downloader = [self delegateOnDataTask:task];
    if (!downloader) {
        return;
    }
    
    [_dicLock lock];
    
    ZXBDownloadItem *item = [downloader matchDownloadItem];
    if (!error) {
        item.state = ZXBDownloadStateDone;
    }else{
        //不是由主动暂停或取消导致的下载失败
        if(item.state!=ZXBDownloadStatePause && item.state!=ZXBDownloadStateCancel){
            [downloader matchDownloadItem].state = ZXBDownloadStateFailed;
        }
    }
    
    //操作数据库
    if(item.state == ZXBDownloadStateDone || item.state == ZXBDownloadStateCancel){
        [_databaseManager deleteItem:item];
    }else{
        [_databaseManager addItem:item];
    }

    [_downloadTaskDic removeObjectForKey:[[downloader matchDownloadItem] resourceId]];
    [_downloadItemDelegateDic removeObjectForKey:[downloader taskIdentifier]];
    [_dicLock unlock];
    
    [downloader URLSession:session task:task didCompleteWithError:error];  
}

- (ZXBResourceDownloader*) delegateOnDataTask:(NSURLSessionTask*) dataTask{
    [_dicLock lock];
    ZXBResourceDownloader *downloader = _downloadItemDelegateDic[@(dataTask.taskIdentifier)];
    [_dicLock unlock];
    
    return downloader;
}

#pragma mark - helper
- (NSError*) checkExceptionBeforeDownload:(ZXBDownloadItem*) item{
    if (!item.itemId || !item.downloadUrl || !item.moudleId){
        NSError *error = [NSError errorWithDomain:ZXBDownloadErrorDomain code:ZXBDownloadErrorInvalidateParams userInfo:@{NSLocalizedDescriptionKey:@"下载参数异常"}];
        return error;
    }
    
    if (![self canAcceptNewTask]) {
        NSError *error = [NSError errorWithDomain:ZXBDownloadErrorDomain code:ZXBDownloadErrorMaxConcurrentNum userInfo:@{NSLocalizedDescriptionKey:@"下载数量已经达到上限"}];
        return error;
    }
    
    [_dicLock lock];
    BOOL isLoading = (_downloadTaskDic[[item resourceId]]!=nil);
    [_dicLock unlock];
    
    if(isLoading){
        NSError *error = [NSError errorWithDomain:ZXBDownloadErrorDomain code:ZXBDownloadErrorItemUnderloading userInfo:@{NSLocalizedDescriptionKey:@"资源正在下载中"}];
        return error;
    }
    
    if(![[ZXBDownloadMoudleManager sharedInstance] moudleWithId:item.moudleId]) {
        NSError *error = [NSError errorWithDomain:ZXBDownloadErrorDomain code:ZXBDownloadErrorUnRegisterMoudle userInfo:@{NSLocalizedDescriptionKey:@"未被注册的下载业务"}];
        return error;
    }
    
    return nil;
}

@end
