functor EndPoint(structure UDP          : UDP
                 structure Event        : EVENT
                 structure HostDispatch : HOST_DISPATCH
                    where type address = UDP.Address.t) 
   : END_POINT =
   struct
      structure Address = UDP.Address
      
      structure ChannelStack = 
         ChannelStack(structure Event = Event
                      structure HostDispatch = HostDispatch)
      structure HostTable = 
         HostTable(structure Event = Event
                   structure ChannelStack = ChannelStack
                   structure HostDispatch = HostDispatch)
      structure Dispatch = 
         ChannelDispatch(structure Address = Address
                         structure HostDispatch = HostDispatch
                         structure ChannelStack = ChannelStack
                         structure Event = Event)
      
      datatype fields = T of
         { udp      : UDP.t,
           table    : HostTable.t,
           dispatch : Dispatch.t,
           handler  : exn -> unit,
           pull     : Event.t,
           ready    : bool,
           rate     : int
           }
      withtype t = fields ref
      
      type host    = HostDispatch.t
      type instream = InStreamQueue.t
      type outstream = OutStreamQueue.t
      type service = Word16.word
      type publickey = Crypto.PublicKey.t
      type privatekey = Crypto.PrivateKey.t
      type publickey_set = Suite.PublicKey.set
      type symmetric_set = Suite.Symmetric.set
      type address = Address.t
      
      type options = { 
         encrypt   : bool, 
         publickey : publickey_set,
         symmetric : symmetric_set
      }
      
      open FunctionalRecordUpdate
      fun get f (ref (T fields)) = f fields
      fun update (this as ref (T fields)) =
         let
            fun from
               v2 v3 v4 v5 v6 v7 v8 =
               {udp=v2,table=v3,dispatch=v4,pull=v5,ready=v6,
                rate=v7,handler=v8}
            fun to f
               {udp=v2,table=v3,dispatch=v4,pull=v5,ready=v6,
                rate=v7,handler=v8} =
               f v2 v3 v4 v5 v6 v7 v8
         in
            Fold.post (makeUpdate7 (from, from, to) fields, 
                       fn z => this := T z)
         end
      
      fun existHost  table k = HostTable.existHost (table, k)
      fun attachHost table (a, r) k = HostTable.attachHost (table, k, a, r)
      
      val bytesSent     = Dispatch.bytesSent     o get#dispatch
      val bytesReceived = Dispatch.bytesReceived o get#dispatch
      val channels      = Dispatch.channels      o get#dispatch
      val key           = Dispatch.key           o get#dispatch
      
      fun whenSafeToDestroy (this, cb) = 
         Dispatch.whenSafeToDestroy (get#dispatch this, cb)
      
      fun contact (this, a, s, cb) = Dispatch.contact (get#dispatch this, a, s, cb)
      
      val hosts = HostTable.hosts o get#table
      fun host          (this, k) = HostTable.host          (get#table this, k)
      fun unadvertise   (this, p) = HostTable.unadvertise   (get#table this, p)
      fun advertise (this, p, cb) = HostTable.advertise (get#table this, p, cb)
      
      fun setRate  (this, x) = update this set#rate  x $
      fun setReady (this, x) = update this set#ready x $
      
      fun recv this = fn
         UDP.DATA { sender, data } =>
            Dispatch.recv (get#dispatch this, 
                           attachHost (get#table this), 
                           existHost  (get#table this),
                           sender, 
                           data,
                           HostTable.numHosts (get#table this))
       | UDP.EXCEPTION e => (get#handler this) e
      
      fun rts this x =
         (setReady (this, x)
          ; if Event.isScheduled (get#pull this) orelse not x
            then ()
            else Event.rescheduleIn (get#pull this, Time.zero))
      
      fun canSend this _ =
         if not (get#ready this) then () else
         let
            val { writer, receiver } = Dispatch.pull (get#dispatch this)
            fun addDelay data =
               let
                  val filled = Word8ArraySlice.length data
                  val delay = Time.fromSeconds filled
                  val rate = get#rate this
                  val delay = 
                     if rate <> 0
                     then Time.divInt (delay, rate)
                     else Time.zero
		  val () = Event.rescheduleIn (get#pull this, delay)
               in
                  data
               end
         in
            (* UDP.send can fail if the network is down.
             * We don't really care because the transport protocol should
             * retry to connect until things go through. Ignore exceptions.
             *)
            UDP.send { udp      = get#udp this, 
                       receiver = receiver, 
                       writer   = addDelay o writer }
            handle e => (get#handler this) e
         end
      
      fun destroy this =
         (HostTable.destroy (get#table this)
          ; Dispatch.destroy (get#dispatch this)
          ; UDP.close (get#udp this)
          ; Event.cancel (get#pull this))
      
      fun new { port, handler, entropy, key, options } =
         let
            val defaults = {
               encrypt   = true,
               publickey = Suite.PublicKey.defaults,
               symmetric = Suite.Symmetric.defaults
            }
            val { encrypt, publickey, symmetric } = getOpt (options, defaults)
            
            val proxyVal = ref NONE
            fun proxy f x = f (valOf (!proxyVal)) x
            val rts = Signal.new (proxy rts)
            val dispatch = 
               Dispatch.new { key = key, rts = rts, entropy = entropy,
                              noEncrypt = not encrypt,
                              publickey = publickey,
                              symmetric = symmetric }
            val table = HostTable.new ()
            val this = ref (T { 
               udp      = UDP.bind (port, proxy recv),
               table    = table,
               dispatch = dispatch,
               handler  = handler,
               pull     = Event.scheduleIn (Time.zero, proxy canSend),
               ready    = false,
               rate     = 0
               })
            val () = proxyVal := SOME this
         in
            this
         end
   end
