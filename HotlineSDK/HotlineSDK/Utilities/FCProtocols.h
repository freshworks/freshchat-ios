//
//  FCProtocols.h
//  HotlineSDK
//
//  Created by Sanjith Kanagavel on 27/06/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//
#import "FCMessageFragments.h"
@protocol HLMessageCellDelegate <NSObject>
    -(void)performActionOn:(FragmentData *)fragment;
    -(BOOL)handleLinkDelegate: (NSURL *)url;
@end

@protocol FCBaseMessageControllerProtocol <NSObject>

@end

@protocol FCBaseMessageModelProtocol <NSObject>

@end

@protocol FCHybridMessageControllerProtocol <FCBaseMessageControllerProtocol>

@end

@protocol FCHybridMessageModelProtocol <FCBaseMessageModelProtocol>

@end
