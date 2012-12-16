#ifndef SINGLEMESSAGEINSTREAM_H
#define SINGLEMESSAGEINSTREAM_H

#include <string>
#include <cusp.h>

namespace CUSP
{

class SingleMessageInStream : private InStream::ReadHandler
{
	public:
		class Handler
		{
			public:
				virtual void onMessage(SingleMessageInStream* stream,
						const std::string& msg) = 0;
				virtual void onMessageReset(SingleMessageInStream* stream) = 0;
		};
		
		SingleMessageInStream(const InStream& is, Handler* handler);
		~SingleMessageInStream();
	private:
		InStream is;
		Handler* handler;
		std::string buffer;
		
		virtual void onReceive(const void* data, int size);
		virtual void onShutdown();
		virtual void onReset();
};

} // namespace CUSP

#endif
