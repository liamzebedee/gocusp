functor ChannelStack(structure Event : EVENT
                     structure HostDispatch : HOST_DISPATCH) 
   :> NEGOTIATION where type host = HostDispatch.t =
   struct
      structure Event = Event
      
      structure CongestionControl = 
         Reno(structure HostDispatch = HostDispatch)
      structure AckCallbacks = 
         FastRetransmit(structure CongestionControl = CongestionControl
                        structure Event = Event)
      structure AckGenerator = 
         DelayedAck(structure AckCallbacks = AckCallbacks
                    structure Event = Event)
      structure Negotiation =
         Negotiation(structure Event = Event
                     structure AckGenerator = AckGenerator
                     structure HostDispatch = HostDispatch)
      
      open Negotiation
   end
