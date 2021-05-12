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

- (nullable XCTTaskTerminationSignature ^)publicTerminationHandler
{
	return objc_getAssociatedObject(self, &PUBLIC_TERMINATION_HANDLER_KEY);
}

- (void)setPublicTerminationHandler:(nullable XCTTaskTerminationSignature ^)terminationHandler
{
	objc_setAssociatedObject(self, &PUBLIC_TERMINATION_HANDLER_KEY, terminationHandler, OBJC_ASSOCIATION_COPY);
}

- (void)setTerminationHandler:(nullable XCTTaskTerminationSignature ^)terminationHandler
{
	[self setPublicTerminationHandler:terminationHandler];
}

- (void)overrideTerminationHandler
{
	/* For the fun, below is the declaration without the
	 * XCTTaskTerminationSignature typealias:
	 *    void (^currentTerminationHandler)(NSTask *) = ((void (^(*)(id, SEL))(NSTask *))HPN_HELPTENDER_CALL_SUPER_NO_ARGS_WITH_SEL_NAME(XCTTaskHelptender, terminationHandler));
	 */
	XCTTaskTerminationSignature ^currentTerminationHandler = ((XCTTaskTerminationSignature ^(*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS_WITH_SEL_NAME(XCTTaskHelptender, terminationHandler));
	[self setPublicTerminationHandler:currentTerminationHandler];
	
	XCTTaskTerminationSignature ^newTerminationHandler = ^(NSTask *task) {
		for (id<XCTTaskExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(XCTTaskExtender)]) {
			XCTTaskTerminationSignature ^additionalTerminationHandler = [extender additionalCompletionHandler];
			if (additionalTerminationHandler != NULL) additionalTerminationHandler(self);
		}
		XCTTaskTerminationSignature ^terminationHandler = [self publicTerminationHandler];
		if (terminationHandler != NULL) terminationHandler(self);
	};
	((void (*)(id, SEL, XCTTaskTerminationSignature ^))HPN_HELPTENDER_CALL_SUPER_WITH_SEL_NAME(XCTTaskHelptender, setTerminationHandler:, newTerminationHandler));
}

- (void)resetTerminationHandler
{
	((void (*)(id, SEL, XCTTaskTerminationSignature ^))HPN_HELPTENDER_CALL_SUPER_WITH_SEL_NAME(XCTTaskHelptender, setTerminationHandler:, self.publicTerminationHandler));
	[self setPublicTerminationHandler:nil];
}

@end
