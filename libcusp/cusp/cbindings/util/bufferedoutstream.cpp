#include "bufferedoutstream.h"

#include "stdlib.h"
#include "string.h"
#include "assert.h"

#define BUF_MIN_ALLOC 1024

namespace CUSP
{

//
// public methods
//

BufferedOutStream::BufferedOutStream(const OutStream& _os, Handler* _handler)
	: os(_os), ready(true), buf(NULL), bufSize(0), bufAlloc(0), handler(_handler), shutdownRequest(NULL)
{
	assert(os.isValid());
	assert(handler);
}

BufferedOutStream::~BufferedOutStream()
{
	reset();
}

void BufferedOutStream::write(const void* data, int size)
{
	if (ready) {
		// write directly
		ready = false;
		os.write(data, size, this);
	} else {
		// append buffer
		appendBuf((const unsigned char*) data, (size_t) size);
	}
}

float BufferedOutStream::getPriority()
{
	return os.getPriority();
}

void BufferedOutStream::setPriority(float priority)
{
	os.setPriority(priority);
}

void BufferedOutStream::shutdown(OutStream::ShutdownHandler* handler)
{
	shutdownRequest = handler;
	if (ready) {
		os.shutdown(handler);
	} // (else: wait for onReady())
}

void BufferedOutStream::reset()
{
	ready = false;
	if (buf) {
		free(buf);
		buf = NULL;
		bufSize = 0;
		bufAlloc = 0;
	}
	os.reset();
}

//
// private methods
//

void BufferedOutStream::allocBuf(size_t size)
{
	if (bufAlloc < size) {
		size_t newAlloc = (size < BUF_MIN_ALLOC) ? BUF_MIN_ALLOC : size;
		while (newAlloc < size)
			newAlloc *= 2;
		buf = (unsigned char*) realloc(buf, newAlloc);
		assert(buf);
		bufAlloc = newAlloc;
	}
}

void BufferedOutStream::appendBuf(const unsigned char* data, size_t len)
{
	size_t newSize = bufSize + len;
	allocBuf(newSize);
	memcpy(buf + bufSize, data, len);
	bufSize = newSize;
}

void BufferedOutStream::onReady()
{
	if (bufSize > 0) {
		// write buffer
		os.write(buf, bufSize, this);
		// clear buffer
		bufSize = 0;
	} else {
		if (shutdownRequest)
			os.shutdown(shutdownRequest);
		else
			ready = true;
	}
}

void BufferedOutStream::onReset()
{
	handler->onReset();
}

} // namespace CUSP
