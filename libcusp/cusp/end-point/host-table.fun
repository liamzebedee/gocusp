functor HostTable(structure Event : EVENT
                  structure ChannelStack : NEGOTIATION
                  structure HostDispatch : HOST_DISPATCH) =
   struct
      
      structure ListenKey =
         struct
            type t = Word16.word
            val eq = op =
            val hash = Hash.word16
         end
         
      structure ListenMap = HashTable(ListenKey)
      structure HostMap = HashTable(Crypto.PublicKey)
      
      type service = Word16.word
      type host = HostDispatch.t
      type t = {
         listen  : (host * service * InStreamQueue.t -> unit) ListenMap.t,
         hosts   : host Weak.t HostMap.t,
         cleanup : Event.t
      }
      
      val wipeTime = Time.fromMinutes 2 (* Clean dead hosts every 2 minutes *)
      
      fun advertise ({ listen, ... }:t, SOME id, cb) =
         if id = 0w0 then raise AddressInUse else
         if Word16.>> (id, 0w14) <> 0w0 then raise AddressInUse else
         (case ListenMap.find (listen, id) of
             SOME _ => raise AddressInUse
           | NONE => (ListenMap.add (listen, id, cb); id))
        | advertise (this as { listen, ... }:t, NONE, cb) =
         if ListenMap.size listen = 16384 then raise AddressInUse else
         let
            val id = Random.word16 (random, NONE)
            val mask = 0wx7fff
            val high = 0wx4000
            val id = Word16.andb (id, mask)
            val id = Word16.orb (id, high)
         in
            case ListenMap.find (listen, id) of
               SOME _ => advertise (this, NONE, cb)
             | NONE => (ListenMap.add (listen, id, cb); id)
         end
      
      fun unadvertise ({ listen, ... }:t, id) =
         ListenMap.remove (listen, id)
      
      fun host ({ hosts, ...}:t, key) =
         Option.mapPartial Weak.get (HostMap.find (hosts, key))
      
      fun numHosts ({ hosts, ... }:t) =
         HostMap.size hosts

      fun existHost z = 
         getOpt (Option.map (fn h => (HostDispatch.poke h; true)) (host z), false)
      
      fun newHost ({ listen, ... }:t, key, address, reconnect) =
         HostDispatch.new {
            key = key,
            address = address,
            global = fn p =>
               Option.map 
               (fn cb => fn (h, f) => cb (h, p, f))
               (ListenMap.find (listen, p)),
            reconnect = reconnect
         }
         
      fun attachHost (this as { hosts, ... }:t, key, address, reconnect) =
         case HostMap.find (hosts, key) of
            SOME host => 
              (case Weak.get host of 
                  SOME host =>
                  let
                     val () = HostDispatch.updateAddress (host, address)
                  in
                     host
                  end
                | NONE =>
                  let
                     val host = newHost (this, key, address, reconnect)
                     val () = HostMap.update (hosts, key, Weak.new host)
                  in
                     host
                  end)
          | NONE =>
            let
               val host = newHost (this, key, address, reconnect)
               val () = HostMap.add (hosts, key, Weak.new host)
            in
               host
            end
      
      fun hosts ({ hosts, ... }:t) =
         Iterator.mapPartial (fn (_, h) => Weak.get h) (HostMap.iterator hosts)
      
      fun cleanup hosts event =
         let
            fun tidy (pubkey, host) =
               if isSome (Weak.get host) then () else
               HostMap.remove (hosts, pubkey)
         in
            Iterator.app tidy (HostMap.iterator hosts)
            ; Event.rescheduleIn (event, wipeTime)
         end
      
      fun destroy { listen, cleanup, hosts } =
         let
            val () = 
               Iterator.app 
               (fn (k, _) => ListenMap.remove (listen, k))
               (ListenMap.iterator listen)
            val () =
               Iterator.app
               (fn (k, h) => (Option.app HostDispatch.destroy (Weak.get h)
                              ; HostMap.remove (hosts, k)))
               (HostMap.iterator hosts)
         in
            Event.cancel cleanup
         end
      
      fun new () = 
         let
            val hosts = HostMap.new ()
         in
            { listen  = ListenMap.new (),
              hosts   = hosts,
              cleanup = Event.scheduleIn (wipeTime, cleanup hosts) }
         end
   end
