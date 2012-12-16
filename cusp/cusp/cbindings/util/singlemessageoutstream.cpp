#include "singlemessageoutstream.h"

#include <assert.h>

namespace CUSP
{

SingleMessageOutStream::SingleMessageOutStream(OutStream& _os,
		const std::string& msg, Handler* _handler)
	: os(_os), handler(_handler)
{
	assert(handler);
	os.write(msg.data(), msg.size(), this);
}

SingleMessageOutStream::SingleMessageOutStream(Host& host, ServiceId service,
		const std::string& msg, Handler* _handler, float priority)
	: handler(_handler)
{
	assert(handler);
	os = host.connect(service);
	if (priority != 0.0f)
		os.setPriority(priority);
	os.write(msg.data(), msg.size(), this);
}

SingleMessageOutStream::~SingleMessageOutStream()
{
	os.reset();
}

void SingleMessageOutStream::onReady()
{
	os.shutdown(this);
}

void SingleMessageOutStream::onReset()
{
	handler->onMessageSent(this, false);
}

void SingleMessageOutStream::onShutdown(bool success)
{
	handler->onMessageSent(this, success);
}

} // namespace CUSP
