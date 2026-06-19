import Testing
@testable import SocialFeedCore

// A concrete sample error for exercising the generic Failure parameter.
private enum SampleError: Error, Equatable { case boom }

struct LoadStateTests {

    @Test func equatesByCaseAndPayload() {
        let loaded: LoadState<[Int], SampleError> = .loaded([1, 2])
        #expect(loaded == .loaded([1, 2]))
        #expect(loaded != .loaded([1]))
        #expect(LoadState<[Int], SampleError>.loading != loaded)
        #expect(LoadState<[Int], SampleError>.error(.boom) == .error(.boom))
    }

    @Test func valueAccessorReturnsLoadedPayloadElseNil() {
        let loaded: LoadState<[Int], SampleError> = .loaded([7])
        #expect(loaded.value == [7])
        #expect(LoadState<[Int], SampleError>.idle.value == nil)
        #expect(LoadState<[Int], SampleError>.loading.value == nil)
        #expect(LoadState<[Int], SampleError>.error(.boom).value == nil)
    }
}
