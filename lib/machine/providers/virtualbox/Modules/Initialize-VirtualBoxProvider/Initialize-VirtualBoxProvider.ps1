if (!$Settings.vm.VirtualizationFirmwareEnabled) {
   Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.virtualization))) -Warn
}