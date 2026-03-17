# Detection Evidence Tracker

Purpose of this document:

- Track each simulation execution with reproducible evidence.
- Record the exact query, observed telemetry, and detection result.
- Preserve tuning history and retest decisions for reviewers.

## Lab Results (Current Session)

| Run Date (UTC)                         | Test ID | Simulation Origin | Telemetry Host | Query Used                                                                                                                                                                                 | Result       | Notes                                                                                     |
| -------------------------------------- | ------- | ----------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------ | ----------------------------------------------------------------------------------------- |
| 2026-03-08 11:21                       | SIM-01  | vm-client         | vm-ad          | `index=main host="vm-ad" sourcetype="WinEventLog:Security" (EventCode=4625 OR EventID=4625) earliest=-30m`                                                                                 | detected     | 5 events found; expected for remote SMB auth attempts                                     |
| 2026-03-08 12:00 (minute not captured) | SIM-02  | vm-client         | vm-client      | `index=main host="vm-client" sourcetype="WinEventLog:Microsoft-Windows-PowerShell/Operational" (EventCode=4103 OR EventCode=4104 OR "Test-NetConnection") earliest=-30m`                   | not detected | Insufficient command-content telemetry for `Test-NetConnection` in current logging policy |
| 2026-03-08 13:52                       | SIM-03  | vm-client         | vm-client      | `index=main host="vm-client" sourcetype="WinEventLog:Microsoft-Windows-PowerShell/Operational" (EventCode=4103 OR EventCode=4104 OR "EncodedCommand" OR "Host Application") earliest=-30m` | detected     | EventCode 4103 showed encoded PowerShell execution context                                |
| 2026-03-08 14:34                       | SIM-04  | vm-client         | vm-client      | `index=main host="vm-client" ("whoami /all" OR "net user" OR "net localgroup administrators") earliest=-30m`                                                                               | not detected | No command-content hits for native enumeration commands under current baseline telemetry  |
| 2026-03-08 15:16                       | SIM-05  | vm-client         | vm-client      | `index=main host="vm-client" sourcetype="WinEventLog:Microsoft-Windows-TaskScheduler/Operational" (EventCode=106 OR EventCode=140 OR EventCode=141 OR "LabSimTask") earliest=-30m`         | detected     | Detected after tuning by collecting TaskScheduler Operational channel                     |

## Detailed Run Records

### Run: 2026-03-08 11:21 UTC - SIM-01

- Test ID: SIM-01
- Host (simulation origin): vm-client
- Operator: corp\azureuser
- Start time (UTC): 2026-03-08 11:21
- End time (UTC): 2026-03-08 11:26
- Command(s) executed: `1..5 | ForEach-Object { cmd /c "net use \\10.10.2.4\IPC$ /user:corp\fakeuser WrongPassword123!" | Out-Null }`
- Expected telemetry: failed logon events on the system receiving the logon request (`vm-ad`)
- Splunk query: `index=main host="vm-ad" sourcetype="WinEventLog:Security" (EventCode=4625 OR EventID=4625) earliest=-30m`
- Splunk time range: last 30 minutes
- Key fields observed: `ComputerName=vm-ad.corp.local`, `Workstation Name=vm-client`, `Source Network Address=10.10.3.4`, `Account Name=fakeuser`, `Status=0xC000006D`, `SubStatus=0xC0000064`
- Event IDs observed: 4625
- Detection result: `detected`
- Tuning changes made: switched query host target from `vm-client` to `vm-ad`
- Re-test required: `no`
- Follow-up action: proceed to SIM-02

### Run: 2026-03-08 12:00 UTC (minute not captured) - SIM-02

- Test ID: SIM-02
- Host (simulation origin): vm-client
- Operator: corp\azureuser
- Start time (UTC): 2026-03-08 12:00 (minute not captured)
- End time (UTC): 2026-03-08 12:00 (minute not captured)
- Command(s) executed: `Test-NetConnection -ComputerName 10.10.2.4 -Port 445`, `-Port 3389`, `-Port 135`
- Expected telemetry: PowerShell Operational events linked to recon/connectivity probes from `vm-client`
- Splunk query: `index=main host="vm-client" sourcetype="WinEventLog:Microsoft-Windows-PowerShell/Operational" (EventCode=4103 OR EventCode=4104 OR "Test-NetConnection") earliest=-30m`
- Splunk time range: last 30 minutes
- Key fields observed: none for command content; only baseline `Security/System/Application` sourcetypes present on host inventory check
- Event IDs observed: none attributable to SIM-02 command content
- Detection result: `not detected`
- Tuning changes made: enabled PowerShell Operational channel and verified a synthetic marker event was ingested
- Re-test required: `yes`
- Follow-up action: continue to SIM-03 while keeping SIM-02 marked as not detected due to insufficient command-content telemetry in this lab baseline

### Run: 2026-03-08 13:52 UTC - SIM-03

- Test ID: SIM-03
- Host (simulation origin): vm-client
- Operator: corp\azureuser
- Start time (UTC): 2026-03-08 13:52
- End time (UTC): 2026-03-08 13:55
- Command(s) executed: `powershell.exe -NoProfile -EncodedCommand SQBlAHgAIAAnAFMAdQBzAHAAaQBjAGkAbwB1AHMAUABvAHcAZQByAFMAaABlAGwAbABBAGMAdABpAHYAaQB0AHkAJwA=`
- Expected telemetry: PowerShell Operational pipeline/script execution events showing encoded command usage
- Splunk query: `index=main host="vm-client" sourcetype="WinEventLog:Microsoft-Windows-PowerShell/Operational" (EventCode=4103 OR EventCode=4104 OR "EncodedCommand" OR "Host Application") earliest=-30m`
- Splunk time range: last 30 minutes
- Key fields observed: `EventCode=4103`, `LogName=Microsoft-Windows-PowerShell/Operational`, `Host Application` includes `powershell.exe -NoProfile -EncodedCommand ...`, `User = CORP\\azureuser`, `ComputerName=vm-client.corp.local`
- Event IDs observed: 4103
- Detection result: `detected`
- Tuning changes made: broadened query to include Operational fields (`Host Application`, `EncodedCommand`)
- Re-test required: `no`
- Follow-up action: proceed to SIM-04

### Run: 2026-03-08 14:34 UTC - SIM-04

- Test ID: SIM-04
- Host (simulation origin): vm-client
- Operator: corp\azureuser
- Start time (UTC): 2026-03-08 14:34
- End time (UTC): 2026-03-08 14:36
- Command(s) executed: `whoami /all`, `net user`, `net localgroup administrators`
- Expected telemetry: command-content evidence for local enumeration activity on `vm-client`
- Splunk query: `index=main host="vm-client" ("whoami /all" OR "net user" OR "net localgroup administrators") earliest=-30m`
- Splunk time range: last 30 minutes
- Key fields observed: none for these command strings; ingestion and PowerShell Operational sourcetype health verified separately
- Event IDs observed: none attributable to SIM-04 command-content query
- Detection result: `not detected`
- Tuning changes made: validated telemetry pipeline (`index=main` and PowerShell Operational ingestion present), then broadened checks without command-content hit for native `whoami/net` pattern
- Re-test required: `yes`
- Follow-up action: proceed to SIM-05; optionally re-test SIM-04 with PowerShell-native enumeration cmdlets

### Run: 2026-03-08 15:16 UTC - SIM-05

- Test ID: SIM-05
- Host (simulation origin): vm-client
- Operator: corp\azureuser
- Start time (UTC): 2026-03-08 15:16
- End time (UTC): 2026-03-08 15:19
- Command(s) executed: `$taskName = "LabSimTask"`, `schtasks /create /tn $taskName /tr "cmd.exe /c echo lab-sim" /sc once /st 23:59 /f`, `schtasks /query /tn $taskName`, `schtasks /delete /tn $taskName /f`
- Expected telemetry: scheduled-task registration/update/deletion events on `vm-client`
- Splunk query: `index=main host="vm-client" sourcetype="WinEventLog:Microsoft-Windows-TaskScheduler/Operational" (EventCode=106 OR EventCode=140 OR EventCode=141 OR "LabSimTask") earliest=-30m`
- Splunk time range: last 30 minutes
- Key fields observed: `EventCode=106`, `EventCode=140`, `EventCode=141`, `TaskCategory=Task registered|Task registration updated|Task registration deleted`, `Message` includes `"CORP\\azureuser"` and `"\\LabSimTask"`
- Event IDs observed: 106, 140, 141
- Detection result: `detected`
- Tuning changes made: added `[WinEventLog://Microsoft-Windows-TaskScheduler/Operational]` to UF `inputs.conf`, restarted `SplunkForwarder`, replaced command-string query with TaskScheduler Operational event-code query
- Re-test required: `no`
- Follow-up action: keep SIM-05 marked as detected-after-tuning; optionally re-test SIM-02 and SIM-04 with additional telemetry tuning

## Reusable Run Template

### Run: <YYYY-MM-DD HH:MM UTC> - <SIM-XX>

- Test ID:
- Host:
- Operator:
- Start time (UTC):
- End time (UTC):
- Command(s) executed:
- Expected telemetry:
- Splunk query:
- Splunk time range:
- Key fields observed:
- Event IDs observed:
- Raw event sample (optional):
- Detection result: `detected` | `not detected` | `noisy`
- Tuning changes made:
- Re-test required: `yes` | `no`
- Follow-up action:

## Minimum Completion Criteria

- Complete records for SIM-01 through SIM-05.
- At least one successful re-test after tuning for any initially missed/noisy simulation.
- Final status summary with pass/fail per simulation.

## Final Summary

- Total simulations run: 5
- Detected without tuning: 2 (SIM-01, SIM-03)
- Detected after tuning: 1 (SIM-05)
- Not detected: 2 (SIM-02, SIM-04)
- Next actions: perform targeted re-tests for SIM-02 and SIM-04 after additional command-content telemetry tuning.
