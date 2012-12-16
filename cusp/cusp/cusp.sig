signature CUSP =
   sig
      (* This exception is thrown by read and write on streams *)
      exception RaceCondition
      (* Thrown when out of listen ports or using a taken fixed port *)
      exception AddressInUse
      
      structure Address : ADDRESS
      structure Event : EVENT
      
      structure Suite  : SUITE
      structure Crypto : CRYPTO where type PublicKey.suite = Suite.PublicKey.suite
      structure InStream : IN_STREAM
      structure OutStream : OUT_STREAM
      
      structure Host : HOST
         where type address = Address.t
         where type instream = InStream.t
         where type outstream = OutStream.t
         where type publickey = Crypto.PublicKey.t
      structure EndPoint : END_POINT
         where type address = Address.t
         where type host = Host.t
         where type instream = InStream.t
         where type outstream = OutStream.t
         where type publickey = Crypto.PublicKey.t
         where type privatekey = Crypto.PrivateKey.t
         where type publickey_set = Suite.PublicKey.set
         where type symmetric_set = Suite.Symmetric.set
   end
