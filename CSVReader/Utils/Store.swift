import Observation

@MainActor
protocol Store<State, Input>: AnyObject, Observable {
    associatedtype State
    associatedtype Input: Sendable

    var state: State { get }

    func trigger(_ input: Input) async
}
