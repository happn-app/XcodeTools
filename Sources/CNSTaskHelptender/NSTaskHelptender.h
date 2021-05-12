@import Foundation;

@import eXtenderZ;



NS_ASSUME_NONNULL_BEGIN

@protocol XCTTaskExtender <HPNExtender>

- (nullable void (^)(NSTask * _Nonnull))additionalCompletionHandler;

@end


@interface XCTTaskHelptender : NSTask <HPNHelptender>

@end

NS_ASSUME_NONNULL_END
