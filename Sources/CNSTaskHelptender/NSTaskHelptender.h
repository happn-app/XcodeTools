@import Foundation;

@import eXtenderZ;



NS_ASSUME_NONNULL_BEGIN

@protocol XCTTaskExtender <HPNExtender>

@property(readonly) void (^additionalCompletionHandler)(NSTask * _Nonnull);

@end


@interface XCTTaskHelptender : NSTask <HPNHelptender>

@end

NS_ASSUME_NONNULL_END
