#import "NSTaskHelptender.h"

@import eXtenderZ.HelptenderUtils;



static char PUBLIC_TERMINATION_HANDLER_KEY;

@implementation XCTTaskHelptender

+ (void)load
{
	[self hpn_registerClass:self asHelptenderForProtocol:@protocol(XCTTaskExtender)];
}

+ (void)hpn_helptenderHasBeenAdded:(XCTTaskHelptender *)helptender
{
	[helptender overrideTerminationHandler];
}

+ (void)hpn_helptenderWillBeRemoved:(XCTTaskHelptender *)helptender
{
	[helptender resetTerminationHandler];
}

- (nullable void (^)(NSTask *))publicTerminationHandler
{
	return objc_getAssociatedObject(self, &PUBLIC_TERMINATION_HANDLER_KEY);
}

- (void)setPublicTerminationHandler:(nullable void (^)(NSTask * _Nonnull))terminationHandler
{
	objc_setAssociatedObject(self, &PUBLIC_TERMINATION_HANDLER_KEY, terminationHandler, OBJC_ASSOCIATION_COPY);
}

- (void)setTerminationHandler:(nullable void (^)(NSTask * _Nonnull))terminationHandler
{
	[self setPublicTerminationHandler:terminationHandler];
}

- (void)overrideTerminationHandler
{
	void (^currentTerminationHandler)(NSTask *) = ((void (^(*)(id, SEL))(NSTask *))HPN_HELPTENDER_CALL_SUPER_NO_ARGS_WITH_SEL_NAME(XCTTaskHelptender, terminationHandler));
	[self setPublicTerminationHandler:currentTerminationHandler];
	
	void (^newTerminationHandler)(NSTask *) = ^(NSTask *task) {
		for (id<XCTTaskExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(XCTTaskExtender)]) {
			void (^additionalTerminationHandler)(NSTask *) = [extender additionalCompletionHandler];
			if (additionalTerminationHandler != NULL) additionalTerminationHandler(self);
		}
		void (^terminationHandler)(NSTask *) = [self publicTerminationHandler];
		if (terminationHandler != NULL) terminationHandler(self);
	};
	((void (*)(id, SEL, void (^)(NSTask *)))HPN_HELPTENDER_CALL_SUPER_WITH_SEL_NAME(XCTTaskHelptender, setTerminationHandler:, newTerminationHandler));
}

- (void)resetTerminationHandler
{
	((void (*)(id, SEL, void (^)(NSTask *)))HPN_HELPTENDER_CALL_SUPER_WITH_SEL_NAME(XCTTaskHelptender, setTerminationHandler:, self.publicTerminationHandler));
	[self setPublicTerminationHandler:nil];
}

@end
