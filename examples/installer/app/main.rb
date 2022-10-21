# Cause configuration steps to be eagerly instantiated.
# Without that, the automatic step handling won't work as expected, as
# the refs to the windows will cause the newly instantiated ones to be shown.
GUI::SystemConfigurationStepsWindow::STEPS.each do |pair|
  step, _ = pair
  GUI.const_get(step).instance
end

GUI::WelcomeWindow.instance.present

LVGUI.main_loop
