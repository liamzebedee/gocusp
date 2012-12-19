(* A Host is a hook to the local information about a remote peer.
 * Hosts are automatically destroyed when there are no open streams or listeners.
 * Any attempt to listen or connect on a destroyed Host will trigger the
 * HostIsDestroyed exception. If you intend to use a host again later, then
 * make sure you have at least one stream or listener used.
 *)
signature HOST =
   sig
      type t
      type address
      type instream
      type outstream
      type publickey
      type service = Word16.word
      
      (* Iterate over non-reset streams attached to this host *)
      val inStreams  : t -> instream  Iterator.t
      val outStreams : t -> outstream Iterator.t
      
      (* Query how much data is buffered. 
       * Be advised that queuedOutOfOrder and queuedInflight may exceed the
       * sum of these buffers from read/outStreams due to reset streams that
       * still consume buffers.
       *)
      val queuedOutOfOrder   : t -> int (* Received, but unreadable *)
      val queuedUnread       : t -> int (* Received, waiting to be read *)
      val queuedInflight     : t -> int (* Inflight awaiting acknowledgment *)
      val queuedToRetransmit : t -> int (* Lost and waiting to be retransmit *)
      
      (* Total traffic sent through this host (including stream headers) *)
      val bytesSent     : t -> LargeInt.int
      val bytesReceived : t -> LargeInt.int
      val lastSend      : t -> Time.t
      val lastReceive   : t -> Time.t
      
      (* The public key of the connected host. *)
      val key : t -> publickey
      (* The remote address, if the host is contacted. *)
      val address : t -> address option
      
      (* Connect to this host *)
      val connect : t * service -> outstream
      
      (* Listen for connections from (only) this host.
       * The returned service name is dynamically assigned.
       * If there are too many listeners bound, then AddressInUse is raised.
       *)
      val listen : t * (service * instream -> unit) -> service
      val unlisten: t * service -> unit
   end
