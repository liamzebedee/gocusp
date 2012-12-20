package examples

import (
	"testing"
	"github.com/liamzebedee/gocusp/cusp"
)

func TestEndpoint(t *testing.T) {
	localEndpoint := cusp.NewEndPoint(12321) // Create new endpoint on port 12321
	t.Logf("Bytes sent: %d", localEndpoint.BytesSent())
}
