param([ValidateSet('arm64-v8a','armeabi-v7a','x86_64')][string]$Abi='arm64-v8a',[switch]$Debug,[string]$DependencyCache,[string]$SigningDirectory,[string]$SdkRoot='C:\Users\Owner\AppData\Local\Android\Sdk',[string]$JdkRoot='C:\Program Files\Eclipse Adoptium\jdk-25.0.3.9-hotspot')
$ErrorActionPreference='Stop'
if(!$SigningDirectory){$SigningDirectory=Join-Path (Split-Path $PSScriptRoot -Parent) '.local'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$repo=Split-Path $PSScriptRoot -Parent;$build=Join-Path $PSScriptRoot ('build\'+$Abi+$(if($Debug){'-debug'}else{''}));$platform=Join-Path $SdkRoot 'platforms\android-35\android.jar';$tools=Join-Path $SdkRoot 'build-tools\36.0.0'
if(!$DependencyCache){$DependencyCache=Join-Path $PSScriptRoot 'build\deps'}
New-Item -ItemType Directory -Force $build,$DependencyCache,"$build\classes","$build\generated","$build\dex","$build\compiled","$build\package\lib\$Abi","$build\package\assets","$build\android-user" | Out-Null
$env:JAVA_HOME=$JdkRoot;$env:ANDROID_USER_HOME="$build\android-user"
function Tool([string]$Exe,[string[]]$Arguments){& $Exe @Arguments;if($LASTEXITCODE){throw "Tool failed: $Exe ($LASTEXITCODE)"}}
$jars=[Collections.Generic.List[string]]::new();$resourceDirs=[Collections.Generic.List[string]]::new();$packages=[Collections.Generic.List[string]]::new();$packages.Add('org.videolan.libvlc')
foreach($dep in (Get-Content -LiteralPath "$PSScriptRoot\dependencies.json" -Raw | ConvertFrom-Json)){
 $file=Join-Path $DependencyCache $dep.file
 if(!(Test-Path -LiteralPath $file)){Invoke-WebRequest -Uri $dep.url -OutFile $file -UseBasicParsing}
 if((Get-FileHash -LiteralPath $file).Hash.ToLowerInvariant() -ne $dep.sha256){throw "Dependency checksum mismatch: $($dep.file)"}
 if($file.EndsWith('.aar')){
  $folder=Join-Path $DependencyCache ([IO.Path]::GetFileNameWithoutExtension($file)+'-unpacked');if(!(Test-Path -LiteralPath $folder)){[IO.Compression.ZipFile]::ExtractToDirectory($file,$folder)}
  if(Test-Path "$folder\classes.jar"){$jars.Add("$folder\classes.jar")}
  if(Test-Path "$folder\libs"){Get-ChildItem "$folder\libs" -Filter '*.jar' | ForEach-Object {$jars.Add($_.FullName)}}
  if(Test-Path "$folder\res"){$resourceDirs.Add("$folder\res")}
  if(Test-Path "$folder\AndroidManifest.xml"){$manifest=[xml][IO.File]::ReadAllText("$folder\AndroidManifest.xml");$pkg=[string]$manifest.manifest.package;if($pkg -and !$packages.Contains($pkg)){$packages.Add($pkg)}}
  if($dep.file.StartsWith('libvlc-all')){Copy-Item "$folder\jni\$Abi\*.so" "$build\package\lib\$Abi";if(Test-Path "$folder\assets"){Copy-Item "$folder\assets\*" "$build\package\assets" -Recurse -Force}}
 }else{$jars.Add($file)}
}
Copy-Item "$PSScriptRoot\assets\*" "$build\package\assets" -Recurse -Force
$resourceDirs.Add("$PSScriptRoot\res")
$flats=[Collections.Generic.List[string]]::new();$number=0
foreach($dir in $resourceDirs){$compiled="$build\compiled\$number";New-Item -ItemType Directory -Force $compiled | Out-Null;foreach($file in (Get-ChildItem $dir -Recurse -File)){Tool "$tools\aapt2.exe" @('compile',$file.FullName,'-o',$compiled)};Get-ChildItem $compiled -Filter '*.flat' | ForEach-Object {$flats.Add($_.FullName)};$number++}
$manifestText=[IO.File]::ReadAllText("$PSScriptRoot\AndroidManifest.xml")
if($Debug){$manifestText=$manifestText.Replace('<application ','<application android:debuggable="true" ');$manifestText=$manifestText.Replace('</manifest>','<instrumentation android:name="io.github.long0823.tclviewer.SmokeTest" android:targetPackage="io.github.long0823.tclviewer"/><instrumentation android:name="io.github.long0823.tclviewer.SettingsTest" android:targetPackage="io.github.long0823.tclviewer"/><instrumentation android:name="io.github.long0823.tclviewer.PairingTest" android:targetPackage="io.github.long0823.tclviewer"/><instrumentation android:name="io.github.long0823.tclviewer.LifecycleTest" android:targetPackage="io.github.long0823.tclviewer"/><instrumentation android:name="io.github.long0823.tclviewer.IptvSettingsTest" android:targetPackage="io.github.long0823.tclviewer"/><instrumentation android:name="io.github.long0823.tclviewer.FullscreenTest" android:targetPackage="io.github.long0823.tclviewer"/></manifest>')}
[IO.File]::WriteAllText("$build\AndroidManifest.xml",$manifestText,[Text.UTF8Encoding]::new($false))
$link=@('link','-o',"$build\base.apk",'-I',$platform,'--manifest',"$build\AndroidManifest.xml",'--java',"$build\generated",'--extra-packages',($packages -join ':'),'--auto-add-overlay')
foreach($file in $flats){$link+=@('-R',$file)}
& "$tools\aapt2.exe" @link
if($LASTEXITCODE){if($LASTEXITCODE -ne -1073741819){throw 'AAPT2 link failed'};Tool 'python' @("$PSScriptRoot\recover-aapt-zip.py","$build\base.apk");Tool "$tools\aapt2.exe" @('dump','badging',"$build\base.apk")}
$sources=@(Get-ChildItem "$PSScriptRoot\src","$build\generated" -Filter '*.java' -Recurse | ForEach-Object FullName)
if($Debug){$sources+=@(Get-ChildItem "$PSScriptRoot\tests\android" -Filter '*.java' -Recurse | ForEach-Object FullName)}
Tool "$JdkRoot\bin\javac.exe" (@('-encoding','UTF-8','-source','8','-target','8','-classpath',($platform+';'+($jars -join ';')),'-d',"$build\classes")+$sources)
$classes=@(Get-ChildItem "$build\classes" -Filter '*.class' -Recurse | ForEach-Object FullName)
$dexArgs=@('--release','--min-api','26','--lib',$platform,'--output',"$build\dex")+$classes+@($jars)
[IO.File]::WriteAllLines("$build\d8.args",@($dexArgs | ForEach-Object { $_.Replace('\','/') }),[Text.UTF8Encoding]::new($false))
Tool "$tools\d8.bat" @("@$build\d8.args")
Tool "$JdkRoot\bin\jar.exe" @('uf',"$build\base.apk",'-C',"$build\package",'.','-C',"$build\dex",'.')
& "$tools\zipalign.exe" -f 4 "$build\base.apk" "$build\aligned.apk"
if($LASTEXITCODE){if($LASTEXITCODE -ne -1073741819){throw 'Zipalign failed'};Tool 'python' @("$PSScriptRoot\recover-aapt-zip.py","$build\aligned.apk")}
Tool "$tools\zipalign.exe" @('-c','4',"$build\aligned.apk")
$output=Join-Path $build ('TCL-Viewer-0.4.1-'+$Abi+$(if($Debug){'-debug'}else{''})+'.apk')
Tool "$tools\apksigner.bat" @('sign','--ks',"$SigningDirectory\signing.jks",'--ks-pass',"file:$SigningDirectory\signing.pass",'--ks-key-alias','tclbondriver','--out',$output,"$build\aligned.apk")
Tool "$tools\apksigner.bat" @('verify','--verbose',$output)
Write-Output "APK ready: $output"