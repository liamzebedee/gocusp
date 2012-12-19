#ifndef ABORTABLECONTACTHANDLER_H
#define ABORTABLECONTACTHANDLER_H

#include <cusp.h>

namespace CUSP {

class AbortableContactHandler : public EndPoint::ContactHandler
{
	public:
		AbortableContactHandler(EndPoint::ContactHandler& handler);
		void abort();
		
		// EndPoint::ContactHandler implementation
		virtual void onContact(Host& host, OutStream& os);
		virtual void onContactFail();
	
	private:
		EndPoint::ContactHandler* handler;
	
};

} // namespace CUSP

#endif
