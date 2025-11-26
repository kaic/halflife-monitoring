# Antivirus False Positive Fix Guide

## Problem
When running `TempBridge.exe` from the terminal or during installation, your antivirus may flag it as a security threat and quarantine the file.

## Why This Happens
TempBridge is a legitimate hardware monitoring application that:
- **Accesses low-level hardware sensors** (CPU/GPU temperature and usage)
- **Runs without a visible window** (background process)
- **Is compiled as a self-contained, compressed single-file executable**
- **Is not code-signed** (no certificate)

These characteristics can trigger false positives in heuristic antivirus detection.

## Automatic Detection
The `install.bat` script will automatically detect your antivirus and attempt to add exclusions. If automatic configuration fails, follow the manual instructions below for your specific antivirus product.

---

## Manual Exclusion Instructions

### Path to Add as Exclusion
Add one or both of these paths to your antivirus exclusions:
- **File**: `%LocalAppData%\TempBridge\TempBridge.exe`
- **Folder**: `%LocalAppData%\TempBridge`

You may also want to add your development directory:
- `C:\Users\YourName\dev\projects\halflife-monitoring`

---

## 1. Windows Defender (Microsoft Defender)

### Method 1: GUI
1. Open **Windows Security** (search in Start menu)
2. Go to **Virus & threat protection**
3. Click **Manage settings** under "Virus & threat protection settings"
4. Scroll down to **Exclusions** → Click **Add or remove exclusions**
5. Click **Add an exclusion** → Choose **Folder**
6. Navigate to `%LocalAppData%\TempBridge` and select it
7. Click **Select Folder**

### Method 2: PowerShell (Administrator)
```powershell
Add-MpPreference -ExclusionPath "$env:LocalAppData\TempBridge"
```

---

## 2. Bitdefender

### Method 1: GUI (Recommended)
1. **Open Bitdefender** (system tray icon)
2. Go to **Protection** → **Antivirus** → **Settings**
3. Scroll to **Exclusions** section
4. Click **Manage Exceptions**
5. Click **Add Exception**
6. Choose **Process** or **Folder**
7. Add: `%LocalAppData%\TempBridge\TempBridge.exe`
8. Click **Save**

### Method 2: Restore from Quarantine
If already quarantined:
1. **Protection** → **Quarantine**
2. Find `TempBridge.exe`
3. Right-click → **Restore and add to exceptions**

### Portuguese Interface:
**Proteção** → **Antivírus** → **Configurações** → **Exclusões** → **Gerenciar Exceções**

---

## 3. Avast Free Antivirus

1. Open **Avast** user interface
2. Go to **Menu** (☰) → **Settings**
3. Select **General** → **Exceptions**
4. Click **Add Exception**
5. Click **Browse** and navigate to:
   - `%LocalAppData%\TempBridge\TempBridge.exe`
6. Click **Add Exception**
7. Optionally check **Exclude from all shields**

---

## 4. AVG Antivirus

1. Open **AVG** user interface
2. Go to **Menu** (☰) → **Settings**
3. Select **General** → **Exceptions**
4. Click **Add Exception**
5. Browse to `%LocalAppData%\TempBridge\TempBridge.exe`
6. Click **Add Exception**

---

## 5. Norton 360 / Symantec

1. Open **Norton 360**
2. Click **Settings**
3. Go to **Antivirus** → **Scans and Risks**
4. Click **Exclusions / Low Risks**
5. Under **Items to Exclude from Scans**, click **Configure**
6. Click **Add Folders** or **Add Files**
7. Navigate to `%LocalAppData%\TempBridge`
8. Click **OK** → **Apply**

---

## 6. McAfee Total Protection

1. Open **McAfee** console
2. Click **Virus and Spyware Protection**
3. Click **Real-Time Scanning**
4. Click **Excluded Files**
5. Click **Add File** or **Add Folder**
6. Browse to `%LocalAppData%\TempBridge\TempBridge.exe`
7. Click **Add** → **Apply**

---

## 7. Kaspersky (Internet Security / Total Security)

1. Open **Kaspersky** main window
2. Click **Settings** (⚙️ gear icon at bottom)
3. Go to **Additional** → **Threats and Exclusions**
4. Click **Manage Exclusions** under "Exclusions"
5. Click **Add**
6. Choose **Browse** → Navigate to:
   - `%LocalAppData%\TempBridge\TempBridge.exe`
7. Click **Add**

### Alternative Path:
**Settings** → **Protection** → **Exclusions** → **Specify Trusted Applications**

---

## 8. ESET NOD32 / Internet Security

1. Open **ESET** main window
2. Press **F5** (or click **Setup**)
3. Expand **Computer** section
4. Go to **Exclusions**
5. Click **Edit** next to "Exclusions from scanning"
6. Click **Add**
7. Browse to `%LocalAppData%\TempBridge\TempBridge.exe`
8. Click **OK** → **OK**

---

## 9. Avira Antivirus

1. Open **Avira** user interface
2. Go to **Security** → **System Scanner**
3. Click **Configure** (gear icon)
4. Go to **Exceptions** tab
5. Click **Add**
6. Choose **File** or **Folder**
7. Browse to `%LocalAppData%\TempBridge`
8. Click **OK**

---

## 10. Trend Micro (Maximum Security / Internet Security)

1. Open **Trend Micro** main console
2. Click **Settings** (gear icon)
3. Go to **Exception List**
4. Click **Add**
5. Click **Browse** and select:
   - `%LocalAppData%\TempBridge\TempBridge.exe`
6. Click **OK** → **Apply**

---

## 11. Malwarebytes Premium

1. Open **Malwarebytes**
2. Click **Settings** (gear icon)
3. Go to **Security** tab
4. Scroll to **Exclusions** section
5. Click **Add Exclusion**
6. Choose **Exclude a File or Folder**
7. Browse to `%LocalAppData%\TempBridge\TempBridge.exe`
8. Click **Exclude**

---

## 12. Sophos Home / Endpoint

1. Open **Sophos** dashboard
2. Go to **Configure** → **Exclusions**
3. Click **Add Exclusion**
4. Choose **Path**
5. Enter: `%LocalAppData%\TempBridge\TempBridge.exe`
6. Set scope: **Scanning**
7. Click **Add**

---

## Verification Steps

After adding the exclusion:

1. **Restore the file** (if quarantined)
2. **Run `install.bat` as Administrator** again
3. **Check if TempBridge is running**:
   ```cmd
   tasklist | findstr TempBridge
   ```
4. **Check logs**:
   - Installation log: `%LocalAppData%\TempBridge\launcher.log`
   - Runtime log: `%LocalAppData%\TempBridge\tempbridge.log`

---

## Additional Notes

### Why is this a false positive?
- **TempBridge is open source** - you can inspect the code on GitHub
- **No network activity** - TempBridge only reads hardware sensors locally
- **No system modifications** - only writes data to a text file for Rainmeter
- **Digitally unsigned** - as an open-source project, we don't have a code signing certificate (costs $300+/year)

### Submitting to Antivirus Vendors
You can help by reporting TempBridge as a false positive:

- **Windows Defender**: https://www.microsoft.com/en-us/wdsi/filesubmission
- **Bitdefender**: https://www.bitdefender.com/submit/
- **Kaspersky**: https://support.kaspersky.com/virlab/helpdesk
- **Avast/AVG**: https://www.avast.com/false-positive-file-form.php
- **Norton**: https://submit.norton.com/
- **McAfee**: https://www.mcafee.com/enterprise/en-us/threat-center/submit-suspicious-file.html

### Code Signing (Future)
We're considering obtaining a code signing certificate to eliminate false positives. If you'd like to sponsor this (~$300/year), please reach out!

---

## Still Having Issues?

1. **Check the logs** in `%LocalAppData%\TempBridge\`
2. **Try running as Administrator** (right-click → Run as Administrator)
3. **Temporarily disable your antivirus** during installation (not recommended long-term)
4. **Open a GitHub issue** with:
   - Your antivirus product and version
   - Log files from `%LocalAppData%\TempBridge\`
   - Any error messages you see

---

## Quick Reference Table

| Antivirus | Auto-Detection | Manual Configuration Required |
|-----------|----------------|-------------------------------|
| Windows Defender | ✅ Automatic | ❌ No (handled by script) |
| Bitdefender | ⚠️ Detected | ✅ Yes (via GUI) |
| Avast | ⚠️ Detected | ✅ Yes (via GUI) |
| AVG | ⚠️ Detected | ✅ Yes (via GUI) |
| Norton | ⚠️ Detected | ✅ Yes (via GUI) |
| McAfee | ⚠️ Detected | ✅ Yes (via GUI) |
| Kaspersky | ⚠️ Detected | ✅ Yes (via GUI) |
| ESET | ⚠️ Detected | ✅ Yes (via GUI) |
| Avira | ⚠️ Detected | ✅ Yes (via GUI) |
| Trend Micro | ⚠️ Detected | ✅ Yes (via GUI) |
| Malwarebytes | ⚠️ Detected | ✅ Yes (via GUI) |
| Sophos | ⚠️ Detected | ✅ Yes (via GUI) |

**Legend:**
- ✅ = Fully automated
- ⚠️ = Detected but requires manual exclusion
- ❌ = Not detected / Not needed
