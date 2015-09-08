#import <UIKit/UIKit.h>
#import "FDKit.h"

/** \class PTSMessagingCell
    \brief This class extends a UITableViewCell with a style similar to that of the SMS-App (iOS). It displays a text-message of any size (only limited by the capabilities of UIView), a timestamp (if given) and an avatar-Image (if given). 
 
    The cell will properly respond to orientation-changes and can be displayed on iPhones and iPads. The usage of this class is very simple: Initialize it, using the initMessagingCellWithReuseIdentifier:(NSString*)reuseIdentifier-Method and afterwards set its properties, as you would with a commom UITabelViewCell.
 
    The class also implements behaviour regarding gesture recognizers and Copy/Paste. The PTSMessagingCells are selectable and its content can be copied to the clipboard.
 
    @author Ralph Gasser
    @date 2011-08-08
    @version 1.5
    @copyright Copyright 2012, pontius software GmbH
 */

@protocol DeeplinkDelegate <NSObject>

@required

- (void)receiveSolutionLinkTap:(NSString *)URLString;

@end

@interface FDMessagingCell : UITableViewCell {
    /*Subview of the MessaginCell, containing the Avatar-Image (if specified). It can be set in the cellForRowAtIndexPath:-Method.*/
    UIImageView* avatarImageView;
    
    /*Subview of the MessaginCell, containing the source (if specified). It can be set in the cellForRowAtIndexPath:-Method.*/
    UILabel* sourceLabel;

    /*Subview of the MessagingCell, containing the image attachment. It can be set in the cellForRowAtIndexPath:-Method.*/
    UIImageView* imagePreview;

    /*Subview of the MessagingCell, containing the actual sent message. It can be set in the cellForRowAtIndexPath:-Method.*/
    FDSTTweetLabel* sentMessageLabel;

    /*Subview of the MessagingCell, containing the actual received message. It can be set in the cellForRowAtIndexPath:-Method.*/
    FDSTTweetLabel* receivedMessageLabel;

    /*Subview of the MessaginCell, containing the timestamp (if specified). It can be set in the cellForRowAtIndexPath:-Method.*/
    UILabel* timeLabel;

    /*Specifies, if the message of the current cell was received or sent. This influences the way, the cell is rendered.*/
    BOOL sent;
    
    /*This is a private subview of the MessagingCell. It is not intended do be editable.*/
    @private UIView * messageView;
    
    /*This is a private subview of the MessagingCell, containing the ballon-graphic. It is not intended do be editable.*/
    @private UIImageView * balloonView;
}


@property (nonatomic, readonly) UIView * messageView;

@property (nonatomic, readonly) UILabel * sourceLabel;

@property (nonatomic, readonly) UIImageView * imagePreview;

@property (nonatomic, readonly) FDSTTweetLabel * sentMessageLabel;

@property (nonatomic, readonly) FDSTTweetLabel * receivedMessageLabel;

@property (nonatomic, readonly) UILabel * timeLabel;

@property (nonatomic, readonly) UIImageView * avatarImageView;

@property (nonatomic, readonly) UIImageView * balloonView;

@property (assign) BOOL sent;

@property (strong, nonatomic) UIFont *messageLabelFont;

@property (nonatomic) NSNumber* source;

@property (weak, nonatomic) id<DeeplinkDelegate> delegate;

/**Returns the text margin in horizontal direction.
 @return CGFloat containing the horizontal text margin.
 */
+(CGFloat)textMarginHorizontal;

/**Returns the text margin in vertical direction.
    @return CGFloat containing the vertical text margin.
*/
+(CGFloat)textMarginVertical;

/** Returns the maximum width for a single message. The size depends on the UIInterfaceIdeom (iPhone/iPad). FOR CUSTOMIZATION: To edit the maximum width, edit this method.
 @return CGFloat containing the maximal width.
 */
+(CGFloat)maxTextWidth;

/** Calculates and returns the size of a frame containing the message, that is given as a parameter.
    @param message NSString containing the message string.
    @return CGSize containing the size of the message (w/h).
 */
+(CGSize)messageSize:(NSString*)message forFont:(UIFont *)messageFont;

+(CGSize)rateOnAppStoreLabelSize:(NSString*)ratingMessage forFont:(UIFont *)reviewFont;
/**  Returns the ballon-Image for specified conditions.
    @param sent Indicates, wheather the message has been sent or received.
    @param selected Indicates, wheather the cell has been selected.
 FOR CUSTOMIZATION: To edit the image, user your own names in this method.
*/

+(CGSize)imageSize:(CGSize)imgSize forTextSize:(CGSize)txtSize;

+(UIImage*)balloonImage:(BOOL)sent isSelected:(BOOL)selected;

/**Initializes the PTSMessagingCell.
    @param reuseIdentifier NSString* containing a reuse Identifier.
    @return Instanze of the initialized PTSMessagingCell. 
*/
-(id)initMessagingCellWithReuseIdentifier:(NSString*)reuseIdentifier;

-(id)initRatingCellWithReuseIdentifier:(NSString*)reuseIdentifier;

@end

