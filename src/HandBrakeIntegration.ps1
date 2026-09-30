function Add-ToHandBrakeQueue {
    param([Parameter(Mandatory)][string[]]$SourceFiles)
    # Native Windows GUI queue injection is deliberately isolated here.
    # HandBrake documents GUI queue export -> CLI import, but not external injection into a running GUI queue.
    return [pscustomobject]@{ Success = $false; Reason = 'NativeGuiQueueIntegrationPending'; Files = $SourceFiles }
}
