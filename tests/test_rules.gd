extends SceneTree

var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	var flow := SessionFlow.new()
	check(not flow.transition(SessionFlow.State.REWARD), "menu cannot skip directly to rewards")
	check(flow.state == SessionFlow.State.MENU, "rejected transition leaves state intact")
	check(flow.begin_run(42), "new run begins in preparation")
	check(flow.run_seed == 42, "run seed retained")
	check(not flow.begin_run(99), "cannot overwrite active run")
	check(flow.run_seed == 42, "rejected begin preserves seed")
	check(flow.transition(SessionFlow.State.COMBAT), "preparation enters combat")
	check(flow.transition(SessionFlow.State.REWARD), "combat enters reward")
	check(flow.transition(SessionFlow.State.COMBAT), "reward returns to combat")
	check(flow.transition(SessionFlow.State.RESULTS), "combat ends in results")
	check(flow.begin_run(99), "result can begin another run")
	check(flow.run_seed == 99, "restart sets new seed")
	for seed_value in range(100):
		var plan := RoomPlan.generate(seed_value)
		check(plan == RoomPlan.generate(seed_value), "same seed reproduces room plan")
		check(plan[0]["kind"] == "safe", "run always starts safe")
		check(plan[-1]["kind"] == "boss", "run always ends in boss")
		check(plan.size() == 5, "default plan has three combat rooms")
	check(RoomPlan.generate(1, -5).size() == 3, "room count lower bound")
	check(RoomPlan.generate(1, 1000).size() == 14, "room count upper bound")
	print("RULE TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
