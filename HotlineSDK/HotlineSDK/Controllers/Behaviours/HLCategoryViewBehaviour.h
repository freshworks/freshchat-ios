//
//  HLCategoryViewBehaviour.h
//  HotlineSDK
//
//  Created by Hrishikesh on 11/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#ifndef HLCategoryViewBehaviour_h
#define HLCategoryViewBehaviour_h

#import <UIKit/UIKit.h>
#import "HLCategory.h"
#import "Hotline.h"

@protocol HLCategoryViewBehaviourDelegate

-(void) onCategoriesUpdated:(NSArray <HLCategory *> *)categories;
-(BOOL) isEmbedded;

@end

@interface HLCategoryViewBehaviour : NSObject

@property BOOL isFallback;
@property BOOL isFilteredView;

-(instancetype) initWithViewController:(UIViewController <HLCategoryViewBehaviourDelegate> *) viewController andFaqOptions:(FAQOptions *) faqOptions;

-(void) load;
-(void) unload;
-(void) launchConversations;
-(BOOL) canDisplayFooterView;
-(void) setNavigationItem;

@end


#endif /* CategoryViewBehaviour_h */
