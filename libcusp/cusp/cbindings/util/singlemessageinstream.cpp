#include "singlemessageinstream.h"

#include <assert.h>

namespace CUSP
{

SingleMessageInStream::SingleMessageInStream(const InStream& _is, Handler* _handler)
	: is(_is), handler(_handler), buffer()
{
	assert(handler);
	is.read(this);
}

SingleMessageInStream::~SingleMessageInStream()
{
	is.reset();
}

void SingleMessageInStream::onReceive(const void* data, int size)
{
	buffer.append((const char*) data, size);
}

void SingleMessageInStream::onShutdown()
{
	handler->onMessage(this, buffer);
}

void SingleMessageInStream::onReset()
{
	handler->onMessageReset(this);
}

} // namespace CUSP
