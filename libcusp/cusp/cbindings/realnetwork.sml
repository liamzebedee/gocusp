(*
 * Creates a CUSP structure for simply using real (UDP) network
 * connection for transport.
 *)

structure CUSP = CUSP (
	structure UDP = UDP4
	structure Event = Main.Event
)
