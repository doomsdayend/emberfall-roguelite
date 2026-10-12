class_name SessionFlow
extends RefCounted

signal state_changed(previous: State, current: State)

enum State { MENU, PREPARATION, COMBAT, REWARD, RESULTS }

const ALLOWED := {
	State.MENU: [State.PREPARATION],
	State.PREPARATION: [State.COMBAT, State.MENU],
	State.COMBAT: [State.REWARD, State.RESULTS, State.MENU],
	State.REWARD: [State.COMBAT, State.RESULTS, State.MENU],
	State.RESULTS: [State.MENU, State.PREPARATION],
}

var state: State = State.MENU
var run_seed: int = 0

func begin_run(seed_value: int) -> bool:
	if state != State.MENU and state != State.RESULTS:
		return false
	run_seed = seed_value
	return transition(State.PREPARATION)

func transition(next_state: State) -> bool:
	if next_state not in ALLOWED[state]:
		return false
	var previous := state
	state = next_state
	state_changed.emit(previous, state)
	return true
