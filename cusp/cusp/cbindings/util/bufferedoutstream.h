#ifndef BUFFEREDOUTSTREAM_H
#define BUFFEREDOUTSTREAM_H

#include <cusp.h>

namespace CUSP
{

class BufferedOutStream : private OutStream::WriteHandler
{
	public:
		class Handler
		{
			public:
				virtual void onReset() = 0;
		};
		
		BufferedOutStream(const OutStream& os, Handler* handler);
		~BufferedOutStream();

		void write(const void* data, int size);
		float getPriority();
		void setPriority(float priority);
		void shutdown(OutStream::ShutdownHandler* handler);
		void reset();
	
	private:
		OutStream os;
		bool ready;
		unsigned char* buf;
		size_t bufSize;
		size_t bufAlloc;
		Handler* handler;
		OutStream::ShutdownHandler* shutdownRequest;
		
		void allocBuf(size_t size);
		void appendBuf(const unsigned char* data, size_t len);
		
		// OutStream::WriteHandler imeplementation
		virtual void onReady();
		virtual void onReset();
};

} // namespace CUSP

#endif
