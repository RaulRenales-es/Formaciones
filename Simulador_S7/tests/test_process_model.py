from process_model import ProcessModel


def test_start_and_stop_pump() -> None:
    model = ProcessModel()

    model.apply_commands({"start_pump": True})
    assert model.state.pump_run is True
    assert model.state.agitator_run is True

    model.apply_commands({"stop_pump": True})
    assert model.state.pump_run is False
    assert model.state.agitator_run is False


def test_alarms_trigger_with_extreme_levels() -> None:
    model = ProcessModel()
    model.state.tank_level = 95
    model.step()
    assert model.state.alarm_high_level is True
    assert model.state.pump_fault is True


def test_emergency_stop_forces_shutdown() -> None:
    model = ProcessModel()
    model.state.emergency_stop = True
    model.state.pump_run = True
    model.state.valve_open = True
    model.state.agitator_run = True

    model.step()
    assert model.state.pump_run is False
    assert model.state.valve_open is False
    assert model.state.agitator_run is False
