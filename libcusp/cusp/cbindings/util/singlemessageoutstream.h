#ifndef SINGLEMESSAGEOUTSTREAM_H
#define SINGLEMESSAGEOUTSTREAM_H

#include <string>
#include <cusp.h>

namespace CUSP
{

class SingleMessageOutStream : private OutStream::WriteHandler,
		private OutStream::ShutdownHandler
{
	public:
		class Handler
		{
			public:
				virtual void onMessageSent(SingleMessageOutStream* stream,
						bool success) = 0;
		};
		
		SingleMessageOutStream(OutStream& os, const std::string& msg,
				Handler* handler);
		SingleMessageOutStream(Host& host, ServiceId service,
				const std::string& msg, Handler* handler, float priority = 0.0f);
		~SingleMessageOutStream();
	private:
		OutStream os;
		Handler* handler;
		
		virtual void onReady();
		virtual void onReset();
		virtual void onShutdown(bool success);
};

} // namespace CUSP

#endif
