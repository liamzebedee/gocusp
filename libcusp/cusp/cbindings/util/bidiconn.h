#ifndef BIDICONN_H
#define BIDICONN_H

#include <cusp.h>
#include <abortablecontacthandler.h>

namespace CUSP
{

/// An abstract base class for bi-directional (client) connections.
class BiDiConn : private EndPoint::ContactHandler, private Host::ListenHandler,
		private InStream::ReadHandler, private OutStream::WriteHandler,
		private OutStream::ShutdownHandler
{
	public:
		/// Connection event handler interface.
		class Handler
		{
			public:
				/// Called on failure contacting host (using 1st constructor).
				virtual void onContactFail() = 0;
				
				/// Called when data is allowed to be sent.
				virtual void onSendReady() = 0;
				
				/// Called when data is received.
				virtual void onReceiveData(const void* data, int size) = 0;
				
				/// Called the a shutdown has been received.
				virtual void onReceiveShutdown() = 0;
				
				/// Called after shutdown has been invoked locally.
				virtual void onSendShutdownReady(bool success) = 0;
				
				/// Called on both reset of in stream and out stream.
				virtual void onReset() = 0;
		};
		
		/// Creates a (client) connection connecting to given (peer) address using given endpoint.
		BiDiConn(EndPoint& endPoint, const Address& addr, const ServiceId service, Handler& handler);
		
		/// Creates a (client) connection with given host at given service.
		BiDiConn(const Host& h, const ServiceId service, Handler& handler);
		
		/// Server constructor. Takes the in stream that has just connected.
		BiDiConn(const Host& h, const InStream& inStream, Handler& handler);
		
		/// Destructor.
		virtual ~BiDiConn();
		
		const Host& getHost();
		
		/// Sends data.
		virtual void sendData(const void* data, int size);
		
		/// Connection shutdown.
		virtual bool shutdown();
		
		/// Connection reset.
		virtual void reset();
		
	private:
		Handler& handler;
		ServiceId remoteService;
		ServiceId localService;
		Host host;
		InStream is;
		OutStream os;
		AbortableContactHandler* contactHandler;
		
		// EndPoint::ContactHandler implementation
		virtual void onContact(Host& host, OutStream& stream);
		virtual void onContactFail();
		
		// Host::ListenHandler implementation
		virtual void onConnect(ServiceId service, InStream& stream);
		
		// InStream::ReceiveHandler implementation
		virtual void onReceive(const void* data, int size);
		virtual void onShutdown();
		virtual void onReset();
		
		// OutStream::WriteHandler implementation
		virtual void onReady();
		
		// OutStream::ShutdownHandler implementation
		virtual void onShutdown(bool success);
	
};

} // namespace CUSP

#endif
