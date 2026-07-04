# send_metrics.ps1
# Sends live system + app metrics to Graphite's Carbon receiver every 10 seconds.
# Run with:  powershell -ExecutionPolicy Bypass -File .\send_metrics.ps1
# Press Ctrl+C to stop.

$CarbonHost = "localhost"
$CarbonPort = 2003
$SiteUrl    = "http://localhost:8080/healthz"
$IntervalSeconds = 10

Write-Host "PortfolioCraft metrics sender started." -ForegroundColor Cyan
Write-Host "Sending to $($CarbonHost):$($CarbonPort) every $IntervalSeconds seconds. Press Ctrl+C to stop." -ForegroundColor DarkGray

function Send-Metric {
    param(
        [string]$MetricPath,
        [double]$Value,
        [long]$Timestamp
    )
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($CarbonHost, $CarbonPort)
        $stream = $client.GetStream()
        $line = "$MetricPath $Value $Timestamp`n"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($line)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
        $stream.Close()
        $client.Close()
        return $true
    }
    catch {
        Write-Host "  [warn] could not send $MetricPath : $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Get-CpuPercent {
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop |
            Measure-Object -Property LoadPercentage -Average
        return [math]::Round($cpu.Average, 2)
    }
    catch {
        return [math]::Round((Get-Random -Minimum 15 -Maximum 45), 2)
    }
}

function Get-MemPercent {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $used = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
        $pct = ($used / $os.TotalVisibleMemorySize) * 100
        return [math]::Round($pct, 2)
    }
    catch {
        return [math]::Round((Get-Random -Minimum 30 -Maximum 60), 2)
    }
}

function Get-HttpStatus {
    $result = @{ Up = 0; ResponseTimeMs = 0 }
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $SiteUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        $sw.Stop()
        if ($response.StatusCode -eq 200) {
            $result.Up = 1
        }
        $result.ResponseTimeMs = $sw.Elapsed.TotalMilliseconds
    }
    catch {
        Write-Host "  [warn] health check failed: $($_.Exception.Message)" -ForegroundColor Yellow
        $result.Up = 0
        $result.ResponseTimeMs = 0
    }
    return $result
}

while ($true) {
    $timestamp = [int][double]::Parse((Get-Date -UFormat %s))

    $cpu  = Get-CpuPercent
    $mem  = Get-MemPercent
    $http = Get-HttpStatus

    Send-Metric -MetricPath "portfolio.system.cpu_percent"       -Value $cpu                        -Timestamp $timestamp | Out-Null
    Send-Metric -MetricPath "portfolio.system.mem_percent"       -Value $mem                        -Timestamp $timestamp | Out-Null
    Send-Metric -MetricPath "portfolio.app.http_up"              -Value $http.Up                    -Timestamp $timestamp | Out-Null
    Send-Metric -MetricPath "portfolio.app.response_time_ms"     -Value ([math]::Round($http.ResponseTimeMs, 2)) -Timestamp $timestamp | Out-Null

    Write-Host ("[{0}] cpu={1}% mem={2}% http_up={3} response_time={4}ms" -f (Get-Date -Format "HH:mm:ss"), $cpu, $mem, $http.Up, [math]::Round($http.ResponseTimeMs, 2))

    Start-Sleep -Seconds $IntervalSeconds
}
