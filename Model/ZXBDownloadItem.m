//
//  ZXBDownloadItem.m
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/2/27.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import "ZXBDownloadItem.h"

@implementation ZXBDownloadItem

- (instancetype) initWithItemId:(NSString*) itemId moudleId:(NSString*) moudleId url:(NSString*) downloadUrl{
    self = [super init];
    
    if (self) {
        _state = ZXBDownloadStateIdle;
        _downloadProgress = 0;
        _itemId = itemId;
        _downloadUrl = downloadUrl;
        _moudleId = moudleId;
    }
    
    return self;
}


- (NSUInteger) hash{
    if (_itemId) {
        return  _itemId.hash;
    }else{
        return super.hash;
    }
}

- (NSString*) resourceId{
    NSString *userId = [self userId];
    return [NSString stringWithFormat:@"%@%@%@",userId,_itemId,_moudleId];
}

- (NSString*) userId{
    return @"1";
}

@end
