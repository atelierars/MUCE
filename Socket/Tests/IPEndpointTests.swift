import Testing
import Network
@testable import Socket
@Test
func ipv4Endpoint() {
	let origin = IPv4Address("1.2.3.4").unsafelyUnwrapped
	let eval = IPv4Endpoint(addr: origin, port: .http)
	#expect(eval.addr == origin)
	#expect(eval.port == 80)
	#expect(UInt32(bigEndian: eval.sin_addr.s_addr) == 0x01020304)
	#expect(UInt16(bigEndian: eval.sin_port) == 80)
}
