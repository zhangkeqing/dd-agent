# Variables
$version = "$(python -c "from config import get_version; print get_version()").$env:BUILD_NUMBER"

# Remove old artifacts
rm build/*.exe
rm build/*.msi

# Build the agent.exe service
python setup.py py2exe
mkdir packaging\datadog-agent\win32\install_files\files
cp -r dist\* packaging\datadog-agent\win32\install_files\files

# Change to the packaging directory
cd packaging\datadog-agent\win32

# Copy checks.d files into the install_files
mkdir install_files\checks.d
cp ..\..\..\checks.d\* install_files\checks.d

# Copy the conf.d files into the install_files
mkdir install_files\conf.d
cp ..\..\..\conf.d\* install_files\conf.d

# Copy the pup files into the install_files
cp -R ..\..\..\dist\pup install_files\pup


## Generate the CLI installer with WiX

    # Generate fragments for the files in checks.d, conf.d and pup
    heat dir install_files\files -gg -dr INSTALLDIR -var var.InstallFilesBins -cg files -o wix\files.wxs
    heat dir install_files\checks.d -gg -dr INSTALLDIR -var var.InstallFilesChecksD -cg checks.d -o wix\checksd.wxs
    heat dir install_files\pup -gg -dr INSTALLDIR -var var.InstallFilesPup -cg pup -o wix\pup.wxs
    heat dir install_files\conf.d -gg -dr APPLIDATIONDATADIRECTORY -t wix\confd.xslt -var var.InstallFilesConfD -cg conf.d -o wix\confd.wxs

    # Create .wixobj files from agent.wxs, confd.wxs, checksd.wxs
    $opts = '-dInstallFiles=install_files', '-dWixRoot=wix', '-dInstallFilesChecksD=install_files\checks.d', '-dInstallFilesConfD=install_files\conf.d', '-dInstallFilesPup=install_files\pup', "-dAgentVersion=$version"
    candle $opts wix\agent.wxs wix\checksd.wxs wix\confd.wxs wix\pup.wxs wix\files.wxs

    # Light to create the msi
    light agent.wixobj checksd.wixobj confd.wixobj pup.wixobj files.wixobj -o ..\..\..\build\ddagent.msi

# Clean up
rm *wixobj*
rm -r install_files\*

# Move back to the root workspace
cd ..\..\..\

# Sign the installers
# TODO