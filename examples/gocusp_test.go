package examples

import (
	"testing"
	"github.com/liamzebedee/gocusp/gocusp"
)

func TestEndpoint(t *testing.T) {
	localEndpoint := gocusp.NewEndPoint(12321) // Create new endpoint on port 12321
	t.Logf("%s", localEndpoint)
	//t.Logf("Bytes sent: %d", localEndpoint.BytesSent())
}
