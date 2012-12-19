#include "cusp.h"

// (to disable assert)
// #define NDEBUG

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string>
#include <signal.h>

using namespace CUSP;


class Client : private EndPoint::ContactHandler, private Host::ListenHandler,
		private InStream::ReadHandler, private OutStream::WriteHandler,
		private OutStream::ShutdownHandler, private Event::Handler
{
	private:
		Event event;
		EndPoint ep;
		Host host;
		InStream is;
		OutStream os;
	
	public:
		Client(int localPort, const std::string& hostname)
			: is(), os()
		{
			// init CUSP lib
			cuspInit();
			// create event
			event = Event(Event::create(this));
			// create endpoint and contact
			ep = EndPoint::create(localPort);
			Address addr = Address::fromString(hostname);
			printf("Contacting %s...\n", addr.toString().c_str());
			ep.contact(addr, 23, this);
		}
		
		virtual ~Client()
		{
			// 'delete' CUSP objects -- necessary before cuspShutdown()!
			if (event.isValid()) event = Event();
			if (is.isValid()) {
				is.reset();
				is = InStream();
			}
			if (os.isValid()) {
				os.reset();
				os = OutStream();
			}
			if (host.isValid())
				host = Host();
			ep = EndPoint(),
			// shut down CUSP lib
			cuspShutdown();
		}
		
		void shutdown(EndPoint::SafeToDestroyHandler* handler)
		{
			if (event.isValid())
				event.cancel();
			if (os.isValid())
				os.shutdown(this);
			if (handler)
				ep.whenSafeToDestroy(handler);
		}
		
	private:
		// EndPoint::ContactHandler implementation
		virtual void onContact(Host& h, OutStream& stream)
		{
			host = h;
			printf("Contacted host %s\n", host.toString().c_str());
			// listen for 'callback'
			ServiceId service = host.listen(this);
			// connect & send hello (callback port)
			os = stream;
			printf("  Sending local service id (%d)\n", service);
			os.write(&service, sizeof(ServiceId), this);
		}
		virtual void onContactFail()
		{
			printf("Contact fail.\n");
			cuspStopMain();
		}
		
		// Host::ListenHandler implementation
		virtual void onConnect(ServiceId service, InStream& stream)
		{
			printf("Connect from server.\n");
			is = InStream(stream);
			is.read(this);
			// show streams
			int count = 0;
			for (InStream::Iterator it = host.inStreams(); it.hasNext(); it.next())
				count++;
			for (OutStream::Iterator it = host.outStreams(); it.hasNext(); it.next())
				count++;
			printf("  Now %d streams connected.\n", count);
		}
		
		// InStream::ReadHandler implementation
		virtual void onReceive(const void* data, int size)
		{
			std::string s((char*) data, size);
			printf("Received %d bytes: \"%s\"\n", size, s.c_str());
			is.read(this);
		}
		virtual void onShutdown()
		{
			printf("Shutdown.\n");
			if (os.isValid())
				os.shutdown(this);
		}
		virtual void onReset()
		{
			// (this is InStream OR OutStream reset!!)
			if (is.isValid()) {
				is.reset();
				is = InStream();
			}
			if (os.isValid()) {
				os.reset();
				os = OutStream();
			}
			if (cuspMainRunning()) {
				printf("Reset -> terminate.\n");
				cuspStopMain();
			}
		}
		
		// OutStream::WriteHandler implementation
		virtual void onReady()
		{
			assert(os.isValid());
			event.rescheduleIn(1 * TIME_SECOND);
		}
		
		// OutStream::ShutdownHandler implementation
		virtual void onShutdown(bool success)
		{
			printf("Shut down %s.\n", (success) ? "successfully" : "failed");
			if (!success) {
				os.reset();
				cuspStopMain();
			} // else: wait for instream shutdown
			os = OutStream();
		}
		
		// Event::Handler implemenatation
		virtual void onEvent(const Event& evt)
		{
			std::string data = std::string("some data");
			printf("Write: \"%s\"\n", data.c_str());
			os.write(data.c_str(), data.length(), this);
		}
	
};

class DestroyWait : public EndPoint::SafeToDestroyHandler
{
	public:
		virtual void onSafeToDestroy()
		{
			printf("Now safe to destroy.\n");
			cuspStopMain();
		}
};

int main(int argc, const char** argv)
{
	// 1st param: local port; 2nd param: destination host
	int localPort = (argc >= 2) ? strtol(argv[1], NULL, 10) : 8586;
	std::string hostname = std::string((argc >= 3) ? argv[2] : "localhost");
	
	printf("Start...\n");
	Client client(localPort, hostname);
	cuspMainSigInt();
	
	printf("Shutting down...\n");
	DestroyWait dw;
	client.shutdown(&dw);
	cuspMainSigInt();
	
	printf("Done.\n");
	return 0;
}
