#include "bidiconn.h"

#include <assert.h>

namespace CUSP
{

//
// BiDiConn public
//

BiDiConn::BiDiConn(EndPoint& endPoint, const Address& addr, const ServiceId service, Handler& handler)
	: handler(handler), remoteService(service), localService(0)
{
	contactHandler = new AbortableContactHandler(*this);
	endPoint.contact(addr, remoteService, contactHandler);
}


BiDiConn::BiDiConn(const Host& h, const ServiceId service, Handler& handler)
	: handler(handler), remoteService(service), localService(0), host(h), contactHandler(NULL)
{
	OutStream os = host.connect(remoteService);
	onContact(host, os);
}


BiDiConn::BiDiConn(const Host& h, const InStream& inStream, Handler& handler)
	: handler(handler), remoteService(0), localService(0), host(h), is(inStream), contactHandler(NULL)
{
	is.read(this/*, sizeof(ServiceId)*/); // (size limit has some bug...)
}


BiDiConn::~BiDiConn()
{
	// (abort all operations to avoid any more callbacks)
	reset();
}


const Host& BiDiConn::getHost()
{
	return host;
}


void BiDiConn::sendData(const void* data, int size)
{
	assert(os.isValid());
	os.write(data, size, this);
}


bool BiDiConn::shutdown()
{
	// TODO check state?
	if (os.isValid()) {
		os.shutdown(this);
		return true;
	} else
		return false;
}


void BiDiConn::reset()
{
	if (contactHandler) {
		contactHandler->abort();
		delete contactHandler;
		contactHandler = NULL;
	}
	if (localService)
		host.unlisten(localService);
	if (is.isValid())
		is.reset();
	if (os.isValid())
		os.reset();
}


//
// BiDiConn private
//

void BiDiConn::onContact(Host& host, OutStream& stream)
{
	contactHandler = NULL;
	os = stream; //host.connect(remoteService);
	localService = host.listen(this);
	os.write(&localService, sizeof(ServiceId), this);
}


void BiDiConn::onContactFail()
{
	contactHandler = NULL;
	handler.onContactFail();
}


void BiDiConn::onConnect(ServiceId service, InStream& stream)
{
	assert(service == localService);
	assert(!is.isValid());
	host.unlisten(localService);
	localService = 0;
	is = stream;
	is.read(this);
}


void BiDiConn::onReceive(const void* data, int size)
{
	assert(is.isValid());
	if (os.isValid()) {
		// -> normal read
		handler.onReceiveData(data, size);
	} else {
		// -> server mode callback service id received
		assert((size_t) size >= sizeof(ServiceId)); // FIXME should reset here!
		remoteService = *((const ServiceId*) data);
		assert(host.isValid());
		os = host.connect(remoteService);
		handler.onSendReady();
		// process further data if available
		if ((size_t) size > sizeof(ServiceId)) {
			handler.onReceiveData(((const char*) data) + sizeof(ServiceId), size - sizeof(ServiceId));
		}
	}
	is.read(this);
}


void BiDiConn::onShutdown()
{
	handler.onReceiveShutdown();
}


void BiDiConn::onShutdown(bool success)
{
	handler.onSendShutdownReady(success);
}


void BiDiConn::onReset()
{
	handler.onReset();
}


void BiDiConn::onReady()
{
	handler.onSendReady();
}


} // namespace CUSP
