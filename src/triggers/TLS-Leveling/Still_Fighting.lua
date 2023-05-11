disableTrigger("Start Capture Room")
disableTrigger("Room Capture Things")
disableTrigger("End Capture Room")
if lookAfterKill then
    killTimer(lookAfterKill)
    lookAfterKill = nil
end