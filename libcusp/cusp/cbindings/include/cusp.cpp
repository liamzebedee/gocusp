#include "cusp.h"

#include <assert.h>
#include <string.h>
#include <algorithm>
#include "libcusp.h"

#ifdef NDEBUG
#define ASSERT_CALL_TRUE(x) x
#else
#define ASSERT_CALL_TRUE(x) assert(x)
#endif

#define HANDLE_NONE -1
#define IS_VALID_HANDLE(h) (h >= 0)
#define ASSERT_HANDLE(h) assert(h >= 0)

namespace CUSP {

//
// Open & close functions
//

unsigned int openCounter = 0;

void cuspInit()
{
	if (openCounter == 0) {
		const char* argv[] = { NULL };
		cusp_open(0, argv);
	}
	openCounter++;
}

void cuspInit(int argc, const char** argv)
{
	assert(openCounter == 0); // parameters can only be bassed in first open call
	cusp_open(argc, argv);
	openCounter++;
}

void cuspMain()
{
	cusp_main();
}

void cuspMainSigInt()
{
	cusp_main_sigint();
}

bool cuspMainRunning()
{
	return cusp_main_running();
}

void cuspStopMain()
{
	cusp_stop_main();
}

void cuspProcessEvents()
{
	cusp_process_events();
}

void cuspShutdown()
{
	assert(openCounter > 0);
	openCounter--;
	if (openCounter == 0) {
		cusp_close();
	}
}

//
// EndPoint
//

EndPoint EndPoint::create(int port, PrivateKey key, bool encrypt,
		PublicKeySuiteSet publicKeySuites, SymmetricSuiteSet symmetricSuites)
{
	Handle handle = cusp_endpoint_new(port, key.handle, encrypt,
			publicKeySuites.set, symmetricSuites.set);
	if (IS_VALID_HANDLE(handle))
		return EndPoint(handle);
	else
		return EndPoint();
}

EndPoint::EndPoint()
	: handle(HANDLE_NONE)
{
}

EndPoint::EndPoint(const EndPoint& e)
{
	if (IS_VALID_HANDLE(e.handle)) {
		handle = cusp_endpoint_dup(e.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

EndPoint::EndPoint(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

EndPoint::~EndPoint()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_endpoint_free(handle));
}

void EndPoint::swap(EndPoint& e)
{
	std::swap(e.handle, handle);
}

EndPoint& EndPoint::operator =(const EndPoint& e)
{
	EndPoint ep(e);
	swap(ep);
	return *this;
}

bool EndPoint::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

void EndPoint::destroy()
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_endpoint_destroy(handle));
}

Abortable EndPoint::whenSafeToDestroy(SafeToDestroyHandler* handler) const
{
	ASSERT_HANDLE(handle);
	assert(handler);
	Handle h = cusp_endpoint_when_safe_to_destroy(handle,
			(void*) safeToDestroyCallback, handler);
	ASSERT_HANDLE(h);
	return Abortable(h);
}

void EndPoint::setRate(int rate)
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_endpoint_set_rate(handle, rate));
}

PrivateKey EndPoint::key() const
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_endpoint_key(handle);
	ASSERT_HANDLE(h);
	return PrivateKey(h);
}

std::string EndPoint::publicKeyStr(PublicKeySuite suite) const
{
	ASSERT_HANDLE(handle);
	int32_t len;
	char* s = (char*) cusp_endpoint_publickey_str(handle, suite.value, &len);
	return std::string(s, len);
}

int64_t EndPoint::bytesSent() const
{
	ASSERT_HANDLE(handle);
	int64_t b = cusp_endpoint_bytes_sent(handle);
	assert(b >= 0);
	return b;
}

int64_t EndPoint::bytesReceived() const
{
	ASSERT_HANDLE(handle);
	int64_t b = cusp_endpoint_bytes_received(handle);
	assert(b >= 0);
	return b;
}

Abortable EndPoint::contact(const Address& addr, ServiceId service, ContactHandler* handler)
{
	ASSERT_HANDLE(handle);
	assert(handler);
	Handle h = cusp_endpoint_contact(handle, addr.handle, service,
			(void*) contactCallback, handler);
	ASSERT_HANDLE(h);
	return Abortable(h);
}

Host::Iterator EndPoint::hosts() const
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_endpoint_hosts(handle);
	ASSERT_HANDLE(h);
	return Host::Iterator(h);
}

Channel::Iterator EndPoint::channels() const
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_endpoint_channels(handle);
	ASSERT_HANDLE(h);
	return Channel::Iterator(h);
}

void EndPoint::advertise(const ServiceId service, AdvertiseHandler* handler)
{
	ASSERT_HANDLE(handle);
	assert(handler);
	ASSERT_CALL_TRUE(cusp_endpoint_advertise(handle, service,
			(void*) advertiseCallback, handler));
}

void EndPoint::unadvertise(const ServiceId service)
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_endpoint_unadvertise(handle, service));
}

void EndPoint::safeToDestroyCallback(void* userData)
{
	assert(userData);
	((SafeToDestroyHandler*) userData)->onSafeToDestroy();
}

void EndPoint::contactCallback(Handle hostHandle, Handle osHandle, void* userData)
{
	assert(userData);
	if (hostHandle >= 0) {
		Host host(hostHandle);
		OutStream os(osHandle);
		((ContactHandler*) userData)->onContact(host, os);
	} else {
		((ContactHandler*) userData)->onContactFail();
	}
}

void EndPoint::advertiseCallback(Handle hostHandle, Handle streamHandle, void* userData)
{
	assert(userData);
	Host host(hostHandle);
	InStream stream(streamHandle);
	((AdvertiseHandler*) userData)->onConnect(host, stream);
}


//
// Address
//

Address Address::fromString(const std::string& str)
{
	Handle handle = cusp_address_from_string((Objptr) str.c_str());
	if (IS_VALID_HANDLE(handle))
		return Address(handle);
	else
		return Address();
}

Address::Address()
	: handle(HANDLE_NONE)
{
}

Address::Address(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

Address::Address(const Address& a)
{
	if (IS_VALID_HANDLE(a.handle)) {
		handle = cusp_address_dup(a.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

Address::~Address()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_address_free(handle));
}

void Address::swap(Address& a)
{
	std::swap(a.handle, handle);
}

Address& Address::operator =(const Address& a)
{
	Address addr(a);
	swap(addr);
	return *this;
}

bool Address::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

std::string Address::toString() const
{
	ASSERT_HANDLE(handle);
	int32_t len;
	char* s = (char*) cusp_address_to_string(handle, &len);
	return std::string(s, len);
}


//
// Host
//

Host::Host()
	: handle(HANDLE_NONE)
{
}

Host::Host(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

Host::Host(const Host& h)
	: handle(handle)
{
	if (IS_VALID_HANDLE(h.handle)) {
		handle = cusp_host_dup(h.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

Host::~Host()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_host_free(handle));
}

void Host::swap(Host& h)
{
	std::swap(h.handle, handle);
}

Host& Host::operator =(const Host& h)
{
	Host host(h);
	swap(host);
	return *this;
}

bool Host::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

OutStream Host::connect(const ServiceId service)
{
	ASSERT_HANDLE(handle);
	Handle osHandle = cusp_host_connect(handle, service);
	assert(osHandle >= 0);
	return OutStream(osHandle);
}

ServiceId Host::listen(ListenHandler* handler)
{
	ASSERT_HANDLE(handle);
	assert(handler);
	ServiceId service = cusp_host_listen(handle, (void*) listenCallback, handler);
	assert(service != 0);
	return service;
}

void Host::unlisten(const ServiceId service)
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_host_unlisten(handle, service));
}

PublicKey Host::key() const
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_host_address(handle);
	ASSERT_HANDLE(h);
	return PublicKey(h);
}

std::string Host::keyStr() const
{
	ASSERT_HANDLE(handle);
	int32_t len;
	char* s = (char*) cusp_host_key_str(handle, &len);
	return std::string(s, len);
}

Address Host::address() const
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_host_address(handle);
	ASSERT_HANDLE(h);
	return Address(h);
}

std::string Host::toString() const
{
	ASSERT_HANDLE(handle);
	int32_t len;
	char* s = (char*) cusp_host_to_string(handle, &len);
	return std::string(s, len);
}

InStream::Iterator Host::inStreams() const
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_host_instreams(handle);
	ASSERT_HANDLE(h);
	return InStream::Iterator(h);
}

OutStream::Iterator Host::outStreams() const
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_host_outstreams(handle);
	ASSERT_HANDLE(h);
	return OutStream::Iterator(h);
}

int Host::queuedOutOfOrder() const
{
	ASSERT_HANDLE(handle);
	int val = cusp_host_queued_out_of_order(handle);
	assert(val >= 0);
	return val;
}

int Host::queuedUnread() const
{
	ASSERT_HANDLE(handle);
	int val = cusp_host_queued_unread(handle);
	assert(val >= 0);
	return val;
}

int Host::queuedInflight() const
{
	ASSERT_HANDLE(handle);
	int val = cusp_host_queued_inflight(handle);
	assert(val >= 0);
	return val;
}

int Host::queuedToRetransmit() const
{
	ASSERT_HANDLE(handle);
	int val = cusp_host_queued_to_retransmit(handle);
	assert(val >= 0);
	return val;
}

int64_t Host::bytesReceived() const
{
	ASSERT_HANDLE(handle);
	int64_t val = cusp_host_bytes_received(handle);
	assert(val >= 0);
	return val;
}

int64_t Host::bytesSent() const
{
	ASSERT_HANDLE(handle);
	int64_t val = cusp_host_bytes_sent(handle);
	assert(val >= 0);
	return val;
}

Time Host::lastReceive() const
{
	ASSERT_HANDLE(handle);
	Time t = cusp_host_last_receive(handle);
	assert(t >= 0);
	return t;
}

Time Host::lastSend() const
{
	ASSERT_HANDLE(handle);
	Time t = cusp_host_last_send(handle);
	assert(t >= 0);
	return t;
}

void Host::listenCallback(ServiceId service, Handle instreamHandle, void* userData)
{
	assert(userData);
	InStream is(instreamHandle);
	((ListenHandler*) userData)->onConnect(service, is);
}


//
// Host::Iterator
//

Host::Iterator::Iterator()
	: handle(HANDLE_NONE)
{
}

Host::Iterator::Iterator(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

Host::Iterator::Iterator(const Host::Iterator& i)
	: handle(handle)
{
	if (IS_VALID_HANDLE(i.handle)) {
		handle = cusp_host_iterator_dup(i.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

Host::Iterator::~Iterator()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_host_iterator_free(handle));
}

void Host::Iterator::swap(Host::Iterator& i)
{
	std::swap(i.handle, handle);
}

Host::Iterator& Host::Iterator::operator =(const Host::Iterator& i)
{
	Iterator it(i);
	swap(it);
	return *this;
}

bool Host::Iterator::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

bool Host::Iterator::hasNext() const
{
	ASSERT_HANDLE(handle);
	return cusp_host_iterator_has_next(handle);
}

Host Host::Iterator::next()
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_host_iterator_next(handle);
	if (IS_VALID_HANDLE(h))
		return Host(h);
	else
		return Host();
}


//
// Channel::Iterator
//

Channel::Iterator::Iterator()
	: handle(HANDLE_NONE)
{
}

Channel::Iterator::Iterator(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

Channel::Iterator::Iterator(const Channel::Iterator& h)
	: handle(handle)
{
	if (IS_VALID_HANDLE(h.handle)) {
		handle = cusp_channel_iterator_dup(h.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

Channel::Iterator::~Iterator()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_channel_iterator_free(handle));
}

void Channel::Iterator::swap(Channel::Iterator& i)
{
	std::swap(i.handle, handle);
}

Channel::Iterator& Channel::Iterator::operator =(const Channel::Iterator& i)
{
	Iterator it(i);
	swap(it);
	return *this;
}

bool Channel::Iterator::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

bool Channel::Iterator::hasNext() const
{
	ASSERT_HANDLE(handle);
	return cusp_channel_iterator_has_next(handle);
}

Channel Channel::Iterator::next()
{
	ASSERT_HANDLE(handle);
	Handle hHost;
	Handle hAddr = cusp_channel_iterator_next(handle, &hHost);
	Address addr = (IS_VALID_HANDLE(hAddr)) ? Address(hAddr) : Address();
	Host host = (IS_VALID_HANDLE(hHost)) ? Host(hHost) : Host();
	return Channel(addr, host);
}


//
// InStream
//

InStream::InStream()
	: handle(HANDLE_NONE)
{
}

InStream::InStream(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

InStream::InStream(const InStream& is)
{
	if (IS_VALID_HANDLE(is.handle)) {
		handle = cusp_instream_dup(is.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

InStream::~InStream()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_instream_free(handle));
}

void InStream::swap(InStream& s)
{
	std::swap(s.handle, handle);
}

bool InStream::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

InStream& InStream::operator =(const InStream& s)
{
	InStream is(s);
	swap(is);
	return *this;
}

void InStream::read(ReadHandler* handler, int maxCount)
{
	ASSERT_HANDLE(handle);
	assert(handler);
	ASSERT_CALL_TRUE(cusp_instream_read(handle, maxCount, (void*) readCallback, handler));
}

void InStream::reset()
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_instream_reset(handle));
}

int InStream::queuedOutOfOrder() const
{
	ASSERT_HANDLE(handle);
	int val = cusp_instream_queued_out_of_order(handle);
	assert(val >= 0);
	return val;
}

int InStream::queuedUnread() const
{
	ASSERT_HANDLE(handle);
	int val = cusp_instream_queued_unread(handle);
	assert(val >= 0);
	return val;
}

int64_t InStream::bytesReceived() const
{
	ASSERT_HANDLE(handle);
	int64_t val = cusp_instream_bytes_received(handle);
	assert(val >= 0);
	return val;
}

void InStream::readCallback(int32_t count, int32_t ofs, void* data,
		void* userData)
{
	assert(userData);
	if (count >= 0) {
		// have to copy data which could be garbage collected after next ML call
		void* buf = malloc((size_t) count);
		assert(buf);
// 		fprintf(stdout, "RECV: ");
// 		fwrite(data, count, 1, stdout);
// 		fprintf(stdout, "\n");
		memcpy(buf, ((char*) data) + ofs, (size_t) count);
		
		((ReadHandler*) userData)->onReceive(buf, count);
		free(buf);
	} else if (count == -2)
		((ReadHandler*) userData)->onShutdown();
	else if (count == -1)
		((ReadHandler*) userData)->onReset();
	else
		assert(0); // invalid status code
}


//
// InStream::Iterator
//

InStream::Iterator::Iterator()
	: handle(HANDLE_NONE)
{
}

InStream::Iterator::Iterator(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

InStream::Iterator::Iterator(const InStream::Iterator& i)
	: handle(handle)
{
	if (IS_VALID_HANDLE(i.handle)) {
		handle = cusp_instream_iterator_dup(i.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

InStream::Iterator::~Iterator()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_instream_iterator_free(handle));
}

void InStream::Iterator::swap(InStream::Iterator& i)
{
	std::swap(i.handle, handle);
}

InStream::Iterator& InStream::Iterator::operator =(const InStream::Iterator& i)
{
	Iterator it(i);
	swap(it);
	return *this;
}

bool InStream::Iterator::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

bool InStream::Iterator::hasNext() const
{
	ASSERT_HANDLE(handle);
	return cusp_instream_iterator_has_next(handle);
}

InStream InStream::Iterator::next()
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_instream_iterator_next(handle);
	if (IS_VALID_HANDLE(h))
		return InStream(h);
	else
		return InStream();
}


//
// OutStream
//

OutStream::OutStream()
	: handle(HANDLE_NONE)
{
}

OutStream::OutStream(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

OutStream::OutStream(const OutStream& os)
{
	if (IS_VALID_HANDLE(os.handle)) {
		handle = cusp_outstream_dup(os.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

OutStream::~OutStream()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_outstream_free(handle));
}

void OutStream::swap(OutStream& s)
{
	std::swap(s.handle, handle);
}

OutStream& OutStream::operator =(const OutStream& s)
{
	OutStream os(s);
	swap(os);
	return *this;
}

bool OutStream::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

float OutStream::getPriority()
{
	ASSERT_HANDLE(handle);
	float priority = cusp_outstream_get_priority(handle);
	assert(priority == priority); // (check for not NaN)
	return priority;
}

void OutStream::setPriority(float priority)
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_outstream_set_priority(handle, priority));
}

void OutStream::write(const void* data, int count, WriteHandler* handler)
{
	ASSERT_HANDLE(handle);
	assert(handler);
	ASSERT_CALL_TRUE(cusp_outstream_write(handle, (void*) data, count,
			(void*) writeCallback, handler));
}

void OutStream::shutdown(ShutdownHandler* handler)
{
	ASSERT_HANDLE(handle);
	assert(handler);
	ASSERT_CALL_TRUE(cusp_outstream_shutdown(handle, (void*) shutdownCallback, handler));
}

void OutStream::reset()
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_outstream_reset(handle));
}

int OutStream::queuedInflight() const
{
	ASSERT_HANDLE(handle);
	int val = cusp_outstream_queued_inflight(handle);
	assert(val >= 0);
	return val;
}

int OutStream::queuedToRetransmit() const
{
	ASSERT_HANDLE(handle);
	int val = cusp_outstream_queued_to_retransmit(handle);
	assert(val >= 0);
	return val;
}

int64_t OutStream::bytesSent() const
{
	ASSERT_HANDLE(handle);
	int64_t val = cusp_outstream_bytes_sent(handle);
	assert(val >= 0);
	return val;
}

void OutStream::writeCallback(int32_t status, void* userData)
{
	assert(userData);
	switch (status) {
		case 0: ((WriteHandler*) userData)->onReady(); break;
		case -1: ((WriteHandler*) userData)->onReset(); break;
		default: assert(0); // invalid status code
	}
}

void OutStream::shutdownCallback(bool success, void* userData)
{
	assert(userData);
	((ShutdownHandler*) userData)->onShutdown(success);
}


//
// OutStream::Iterator
//

OutStream::Iterator::Iterator()
	: handle(HANDLE_NONE)
{
}

OutStream::Iterator::Iterator(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

OutStream::Iterator::Iterator(const OutStream::Iterator& i)
	: handle(handle)
{
	if (IS_VALID_HANDLE(i.handle)) {
		handle = cusp_outstream_iterator_dup(i.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

OutStream::Iterator::~Iterator()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_outstream_iterator_free(handle));
}

void OutStream::Iterator::swap(OutStream::Iterator& i)
{
	std::swap(i.handle, handle);
}

OutStream::Iterator& OutStream::Iterator::operator =(const OutStream::Iterator& i)
{
	Iterator it(i);
	swap(it);
	return *this;
}

bool OutStream::Iterator::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

bool OutStream::Iterator::hasNext() const
{
	ASSERT_HANDLE(handle);
	return cusp_outstream_iterator_has_next(handle);
}

OutStream OutStream::Iterator::next()
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_outstream_iterator_next(handle);
	if (IS_VALID_HANDLE(h))
		return OutStream(h);
	else
		return OutStream();
}


//
// Event
//

Event Event::create(Handler* handler)
{
	assert(handler);
	Handle handle = cusp_event_new((void*) eventCallback, handler);
	ASSERT_HANDLE(handle);
	return Event(handle);
}

Event Event::schedule(const Time& time, Handler* handler)
{
	int handle = cusp_event_schedule(time, (void*) eventCallback, handler);
	ASSERT_HANDLE(handle);
	return Event(handle);
}

Event Event::scheduleIn(const Time& time, Handler* handler)
{
	int handle = cusp_event_schedule_in(time, (void*) eventCallback, handler);
	ASSERT_HANDLE(handle);
	return Event(handle);
}

Time Event::time()
{
	return cusp_event_time();
}

Event::Event()
	: handle(HANDLE_NONE)
{
}

Event::Event(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

Event::Event(const Event& evt)
{
	if (IS_VALID_HANDLE(evt.handle)) {
		handle = cusp_event_dup(evt.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

Event::~Event()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_event_free(handle));
}

void Event::swap(Event& e)
{
	std::swap(e.handle, handle);
}

Event& Event::operator =(const Event& e)
{
	Event event(e);
	swap(event);
	return *this;
}

bool Event::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

void Event::reschedule(const Time& time)
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_event_reschedule(handle, time));
}

void Event::rescheduleIn(const Time& time)
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_event_reschedule_in(handle, time));
}

void Event::cancel()
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_event_cancel(handle));
}

Time Event::timeOfExecution() const
{
	ASSERT_HANDLE(handle);
	Time t = cusp_event_time_of_execution(handle);
	assert(t != -2);
	return t;
}

Time Event::timeTillExecution() const
{
	ASSERT_HANDLE(handle);
	Time t = cusp_event_time_till_execution(handle);
	assert(t != -2);
	return t;
}

bool Event::isScheduled() const
{
	ASSERT_HANDLE(handle);
	return cusp_event_is_scheduled(handle);
}

void Event::eventCallback(Handle eventHandle, void* userData)
{
	assert(userData);
	Event evt(eventHandle);
	((Handler*) userData)->onEvent(evt);
}

//
// Abortable
//

Abortable::Abortable(const Abortable& a)
{
	if (IS_VALID_HANDLE(a.handle)) {
		handle = cusp_abortable_dup(a.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

Abortable::Abortable(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

Abortable::~Abortable()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_abortable_free(handle));
}

void Abortable::swap(Abortable& a)
{
	std::swap(a.handle, handle);
}

Abortable& Abortable::operator =(const Abortable& a)
{
	Abortable ab(a);
	swap(ab);
	return *this;
}

bool Abortable::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

void Abortable::abort()
{
	ASSERT_HANDLE(handle);
	ASSERT_CALL_TRUE(cusp_abortable_abort(handle));
}


//
// PublicKeySuite
//

std::string PublicKeySuite::name() const
{
	assert(isValid());
	int32_t len;
	char* s = (char*) cusp_suite_publickey_name(value, &len);
	return std::string(s, len);
}

float PublicKeySuite::cost() const
{
	assert(isValid());
	return cusp_suite_publickey_cost(value);
}


//
// PublicKeySuiteSet
//

PublicKeySuiteSet PublicKeySuiteSet::all()
{
	return PublicKeySuiteSet(cusp_suiteset_publickey_all());
}

PublicKeySuiteSet PublicKeySuiteSet::defaults()
{
	return PublicKeySuiteSet(cusp_suiteset_publickey_defaults());
}

PublicKeySuite PublicKeySuiteSet::cheapest() const
{
	return PublicKeySuite(cusp_suiteset_publickey_cheapest(set));
}

PublicKeySuiteSet::Iterator PublicKeySuiteSet::iterator() const
{
	return Iterator(set);
}

bool PublicKeySuiteSet::Iterator::hasNext() const
{
	return (set);
}

PublicKeySuite PublicKeySuiteSet::Iterator::next()
{
	uint16_t s = set;
	uint16_t v = 1;
	for (int i = 0; i < 16; i++) {
		if (s & 1) {
			set &= ~v;
			return PublicKeySuite(v);
		}
		s >>= 1;
		v <<= 1;
	}
	return PublicKeySuite(0);
}


//
// SymmetricSuite
//

std::string SymmetricSuite::name() const
{
	assert(isValid());
	int32_t len;
	char* s = (char*) cusp_suite_symmetric_name(value, &len);
	return std::string(s, len);
}

float SymmetricSuite::cost() const
{
	assert(isValid());
	return cusp_suite_symmetric_cost(value);
}


//
// SymmetricSuiteSet
//

SymmetricSuiteSet SymmetricSuiteSet::all()
{
	return SymmetricSuiteSet(cusp_suiteset_symmetric_all());
}

SymmetricSuiteSet SymmetricSuiteSet::defaults()
{
	return SymmetricSuiteSet(cusp_suiteset_symmetric_defaults());
}

SymmetricSuite SymmetricSuiteSet::cheapest() const
{
	return SymmetricSuite(cusp_suiteset_symmetric_cheapest(set));
}

SymmetricSuiteSet::Iterator SymmetricSuiteSet::iterator() const
{
	return Iterator(set);
}

bool SymmetricSuiteSet::Iterator::hasNext() const
{
	return (set);
}

SymmetricSuite SymmetricSuiteSet::Iterator::next()
{
	uint16_t s = set;
	uint16_t v = 1;
	for (int i = 0; i < 16; i++) {
		if (s & 1) {
			set &= ~v;
			return SymmetricSuite(v);
		}
		s >>= 1;
		v <<= 1;
	}
	return SymmetricSuite(0);
}

//
// PublicKey
//

PublicKey::PublicKey()
	: handle(HANDLE_NONE)
{
}

PublicKey::PublicKey(const PublicKey& k)
{
	if (IS_VALID_HANDLE(k.handle)) {
		handle = cusp_publickey_dup(k.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

PublicKey::PublicKey(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

PublicKey::~PublicKey()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_publickey_free(handle));
}

void PublicKey::swap(PublicKey& k)
{
	std::swap(k.handle, handle);
}

PublicKey& PublicKey::operator =(const PublicKey& k)
{
	PublicKey pk(k);
	swap(pk);
	return *this;
}

bool PublicKey::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

std::string PublicKey::toString() const
{
	ASSERT_HANDLE(handle);
	int32_t len;
	char* s = (char*) cusp_publickey_to_string(handle, &len);
	return std::string(s, len);
}

PublicKeySuite PublicKey::suite() const
{
	ASSERT_HANDLE(handle);
	uint16_t suite = cusp_publickey_suite(handle);
	assert(suite);
	return PublicKeySuite(suite);
}

//
// PrivateKey
//

PrivateKey::PrivateKey()
	: handle(HANDLE_NONE)
{
}

PrivateKey::PrivateKey(const PrivateKey& k)
{
	if (IS_VALID_HANDLE(k.handle)) {
		handle = cusp_privatekey_dup(k.handle);
		ASSERT_HANDLE(handle);
	} else
		handle = HANDLE_NONE;
}

PrivateKey::PrivateKey(Handle handle)
	: handle(handle)
{
	ASSERT_HANDLE(handle);
}

PrivateKey::~PrivateKey()
{
	if (IS_VALID_HANDLE(handle))
		ASSERT_CALL_TRUE(cusp_privatekey_free(handle));
}

void PrivateKey::swap(PrivateKey& k)
{
	std::swap(k.handle, handle);
}

PrivateKey& PrivateKey::operator =(const PrivateKey& k)
{
	PrivateKey pk(k);
	swap(pk);
	return *this;
}

bool PrivateKey::isValid() const
{
	return IS_VALID_HANDLE(handle);
}

PrivateKey PrivateKey::create()
{
	Handle h = cusp_privatekey_new();
	if (IS_VALID_HANDLE(h))
		return PrivateKey(h);
	else
		return PrivateKey();
}

std::string PrivateKey::save(const std::string& password) const
{
	ASSERT_HANDLE(handle);
	int32_t len;
	char* s = (char*) cusp_privatekey_save(handle, (Objptr) password.c_str(), &len);
	return std::string(s, len);
}

PrivateKey PrivateKey::load(const std::string& key, const std::string password)
{
	Handle h = cusp_privatekey_load((Objptr) key.c_str(), (Objptr) password.c_str());
	if (IS_VALID_HANDLE(h))
		return PrivateKey(h);
	else
		return PrivateKey();
}

PublicKey PrivateKey::pubkey(PublicKeySuite suite) const
{
	ASSERT_HANDLE(handle);
	Handle h = cusp_privatekey_pubkey(handle, suite.value);
	ASSERT_HANDLE(h);
	return PublicKey(h);
}


}; // namespace CUSP
