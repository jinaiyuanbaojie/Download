//
//  ZXBDownloadMoudle.m
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/2/27.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import "ZXBDownloadMoudle.h"

@implementation ZXBDownloadMoudle

-(instancetype) initWithMoudleId:(NSString*) moudleId{
    self = [super init];
    
    if (self) {
        _moudleId = moudleId;
    }
    
    return self;
}

- (NSUInteger) hash{
    if (_moudleId) {
        return  _moudleId.hash;
    }else{
        return super.hash;
    }
}

@end
