functor CUSP(structure UDP    : UDP
             structure Event  : EVENT)
   :> CUSP where type Address.t = UDP.Address.t
           where type Event.t = Event.t
   =
   struct
      structure Address = UDP.Address
      structure Event = Event
      
      structure Suite = Suite
      structure Crypto = Crypto
      structure InStream = InStreamQueue
      structure OutStream = OutStreamQueue
      
      structure Host = HostDispatch(structure Address = Address
                                    structure Event = Event)
      structure EndPoint = EndPoint(structure UDP = UDP
                                    structure Event = Event
                                    structure HostDispatch = Host)
      
      exception RaceCondition = RaceCondition
      exception AddressInUse = AddressInUse
   end
